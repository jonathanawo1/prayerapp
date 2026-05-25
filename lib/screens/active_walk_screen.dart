import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../models/coordinate.dart';
import '../models/walk_draft.dart';
import '../utils/distance.dart';
import '../widgets/active_walk_map.dart';
import 'walk_summary_screen.dart';

class ActiveWalkScreen extends StatefulWidget {
  const ActiveWalkScreen({super.key});

  @override
  State<ActiveWalkScreen> createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen>
    with SingleTickerProviderStateMixin {
  final List<Coordinate> _path = [];
  late final DateTime _walkStartedAt;
  var _distance = 0.0;
  var _duration = 0;
  var _paused = false;
  var _acquiring = true;
  String? _error;

  StreamSubscription<Position>? _positionSub;
  Timer? _timer;

  // Pulsing animation for the live indicator
  late final AnimationController _pulseCtrl;

  LocationSettings _trackingSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 6,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'PrayerWalk',
          notificationText: 'Recording your prayer walk',
          enableWakeLock: true,
        ),
      );
    }
    return AppleSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 6,
      activityType: ActivityType.fitness,
      showBackgroundLocationIndicator: true,
      pauseLocationUpdatesAutomatically: false,
    );
  }

  @override
  void initState() {
    super.initState();
    _walkStartedAt = DateTime.now();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _error =
          'Location access denied. Enable GPS for PrayerWalk in Settings.');
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Location services are turned off.');
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused) setState(() => _duration++);
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: _trackingSettings(),
    ).listen((pos) {
      if (!mounted || _paused) return;
      final coord = Coordinate(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      setState(() {
        if (_acquiring) _acquiring = false;
        _path.add(coord);
        if (_path.length > 1) {
          _distance = totalPathDistance(_path);
        }
      });
    });
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _timer?.cancel();
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  Future<void> _endWalk() async {
    if (_path.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Walk a little further to record your route.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Finish walk?',
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        content: Text(
          '${formatDistance(_distance)} · ${formatDuration(_duration)}\n\n'
          'Save this walk to your prayer community.',
          style: GoogleFonts.dmSans(
              color: AppColors.textSecondary, height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep walking',
                style: GoogleFonts.dmSans(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Finish',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    _stopTracking();

    final draft = WalkDraft(
      path: List.from(_path),
      distance: _distance,
      duration: _duration,
      startTime: _walkStartedAt,
      endTime: DateTime.now(),
    );

    // Replace this screen with the summary screen so Back goes to HomeShell
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => WalkSummaryScreen(draft: draft)),
    );
  }

  void _cancelWalk() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Discard walk?',
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Your route will not be saved.',
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep recording',
                style: GoogleFonts.dmSans(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard',
                style: GoogleFonts.dmSans(color: AppColors.danger)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _stopTracking();
        if (mounted) Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ───────────────────────────────────────────────
          Positioned.fill(child: ActiveWalkMap(path: _path)),

          // ── Acquiring overlay ─────────────────────────────────
          if (_acquiring && _error == null)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.background.withOpacity(0.92),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary),
                    const SizedBox(height: 20),
                    Text('Acquiring GPS…',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 6),
                    Text('Move outdoors for best accuracy',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // ── Error ─────────────────────────────────────────────
          if (_error != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.danger.withOpacity(0.35)),
                ),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: AppColors.danger, fontSize: 14)),
              ),
            ),

          // ── Top bar ───────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.close,
                      onTap: _cancelWalk,
                    ),
                    const Spacer(),
                    // Live indicator
                    if (!_acquiring && _error == null)
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.danger
                                    .withOpacity(0.4 * _pulseCtrl.value + 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _paused
                                      ? AppColors.warning
                                      : AppColors.danger.withOpacity(
                                          0.5 + 0.5 * _pulseCtrl.value),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _paused ? 'PAUSED' : 'RECORDING',
                                style: GoogleFonts.dmSans(
                                  color: _paused
                                      ? AppColors.warning
                                      : AppColors.danger,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // ── Stats panel ───────────────────────────────────────
          Positioned(
            bottom: 122,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.93),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _WalkStat(value: formatDuration(_duration), label: 'Time'),
                  _Divider(),
                  _WalkStat(
                      value: formatDistance(_distance),
                      label: 'Distance'),
                  _Divider(),
                  _WalkStat(
                      value: formatPace(_distance, _duration),
                      label: 'Pace'),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 400.ms)
              .slideY(begin: 0.1),

          // ── Bottom actions ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    // Pause / resume
                    GestureDetector(
                      onTap: _togglePause,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          _paused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.textPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // End walk
                    Expanded(
                      child: SizedBox(
                        height: 58,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18)),
                            elevation: 8,
                            shadowColor:
                                AppColors.danger.withOpacity(0.4),
                          ),
                          onPressed: _endWalk,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stop_rounded, size: 22),
                              const SizedBox(width: 8),
                              Text('End Walk',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 18),
        ),
      );
}

class _WalkStat extends StatelessWidget {
  const _WalkStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.border,
      );
}
