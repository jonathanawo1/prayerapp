// AppColors.swift
// PrayerWalk

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    static let appBackground = Color(hex: "0A1628")
    static let appSurface = Color(hex: "1A2740")
    static let appPrimary = Color(hex: "FC4C02")
    static let appAccent = Color(hex: "FC4C02")
    static let appTextPrimary = Color(hex: "F0F6FF")
    static let appTextSecondary = Color(hex: "8BA3C7")
    static let appSuccess = Color(hex: "34C759")
    static let appWarning = Color(hex: "FF9F0A")
    static let appError = Color(hex: "FF453A")
    static let appSeparator = Color(hex: "8BA3C7").opacity(0.2)

    static let routePalette: [Color] = [
        Color(hex: "FC4C02"), Color(hex: "00B4D8"), Color(hex: "06D6A0"),
        Color(hex: "FFD166"), Color(hex: "EF476F"), Color(hex: "7B2D8B"),
        Color(hex: "F77F00"), Color(hex: "4361EE"), Color(hex: "3A86FF"),
        Color(hex: "8338EC")
    ]

    static func routeColor(for userId: String) -> Color {
        let hash = abs(userId.hashValue)
        return routePalette[hash % routePalette.count]
    }
}

extension UIColor {
    static let appPrimary = UIColor(Color.appPrimary)
    static let appSurface = UIColor(Color.appSurface)
    static let appBackground = UIColor(Color.appBackground)
    static let appTextPrimary = UIColor(Color.appTextPrimary)

    static func routeColor(for userId: String) -> UIColor {
        UIColor(Color.routeColor(for: userId))
    }
}
