// ActiveWalkViewModel.swift
// PrayerWalk

import Foundation
import Combine
import CoreLocation

@MainActor
final class ActiveWalkViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false
    @Published var isWarmingUp: Bool = true
    @Published var duration: TimeInterval = 0
    @Published var distance: Double = 0
    @Published var path: [WalkCoordinate] = []

    private var startDate: Date = Date()
    private var pauseDate: Date?
    private var accumulatedDuration: TimeInterval = 0

    private var timer: AnyCancellable?
    private var locationCancellable: AnyCancellable?
    private var lastRecordedCoord: WalkCoordinate?

    let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func startWalk() {
        path = []
        distance = 0
        duration = 0
        accumulatedDuration = 0
        pauseDate = nil
        startDate = Date()
        isRecording = true
        isPaused = false
        isWarmingUp = true

        locationService.resetPath()
        locationService.requestPermission()
        locationService.startTracking()

        startTimer()
        subscribeToLocation()
    }

    func pauseWalk() {
        guard isRecording, !isPaused else { return }
        isPaused = true
        pauseDate = Date()
        timer?.cancel()
        locationService.stopTracking()
    }

    func resumeWalk() {
        guard isRecording, isPaused else { return }
        if let pauseDate = pauseDate {
            accumulatedDuration += pauseDate.distance(to: Date())
        }
        pauseDate = nil
        isPaused = false
        locationService.startTracking()
        startTimer()
    }

    func endWalk() -> WalkDraft {
        isRecording = false
        isPaused = false
        timer?.cancel()
        locationService.stopTracking()
        locationCancellable?.cancel()

        let totalDuration = accumulatedDuration + (isPaused ? 0 : startDate.distance(to: Date()))
        let draft = WalkDraft(
            startTime: startDate,
            endTime: Date(),
            path: path,
            distance: distance,
            duration: Int(duration),
            title: "",
            prayerNotes: ""
        )
        return draft
    }

    private func startTimer() {
        let timerStart = Date()
        let baseAccumulated = accumulatedDuration
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.duration = baseAccumulated + timerStart.distance(to: Date())
            }
    }

    private func subscribeToLocation() {
        locationCancellable = locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] location in
                guard let self, self.isRecording, !self.isPaused else { return }
                // Stay in warm-up until GPS accuracy is ≤ 15m
                if self.isWarmingUp {
                    if location.horizontalAccuracy > 0, location.horizontalAccuracy <= 15 {
                        self.isWarmingUp = false
                        let coord = WalkCoordinate(from: location)
                        self.path.append(coord)
                        self.lastRecordedCoord = coord
                    }
                    return
                }
                let coord = WalkCoordinate(from: location)
                if let last = self.lastRecordedCoord {
                    let delta = haversineDistance(from: last, to: coord)
                    if delta > 2 {
                        self.path.append(coord)
                        self.distance += delta
                        self.lastRecordedCoord = coord
                    }
                } else {
                    self.path.append(coord)
                    self.lastRecordedCoord = coord
                }
            }
    }
}
