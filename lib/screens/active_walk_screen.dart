import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/map_style.dart';
import '../models/coordinate.dart';
import '../providers/auth_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';

class ActiveWalkScreen extends StatefulWidget {
  const ActiveWalkScreen({super.key});

  @override
  State<ActiveWalkScreen> createState() => _ActiveWalkScreenState();
}

class _ActiveWalkScreenState extends State<ActiveWalkScreen> {
  GoogleMapController? _mapController;
  final List<Coordinate> _path = [];
  double _distance = 0;
  int _duration = 0;
  bool _saving = false;
  String? _error;

  StreamSubscription<Position>? _positionSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _error = 'Location permission denied. Enable it in settings.');
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final coord = Coordinate(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      setState(() {
        _path.add(coord);
        if (_path.length > 1) {
          _distance = totalPathDistance(_path);
        }
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(coord.toLatLng()),
      );
    });
  }

  void _stopTracking() {
    _positionSub?.cancel();
    _timer?.cancel();
  }

  Future<void> _endWalk() async {
    if (_path.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walk a bit more before ending.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Prayer Walk?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Distance: ${formatDistance(_distance)}\n'
          'Duration: ${formatDuration(_duration)}\n\n'
          'Your walk will be saved to the global map.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Walking',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End & Save'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    _stopTracking();

    setState(() => _saving = true);
    try {
      final userId = context.read<AuthProvider>().userId!;
      await context.read<WalksProvider>().saveWalk(
            userId: userId,
            path: List.from(_path),
            distance: _distance,
            duration: _duration,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save walk: $e';
      });
    }
  }

  void _cancelWalk() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Walk?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Your current walk will be discarded.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Walking',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _stopTracking();
        Navigator.pop(context);
      }
    });
  }

  Set<Polyline> get _polylines {
    if (_path.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('active'),
        points: _path.map((c) => c.toLatLng()).toList(),
        color: const Color(0xFF818CF8),
        width: 5,
        jointType: JointType.round,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _path.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────
          if (!hasLocation)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Acquiring GPS signal…',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Go outside for best accuracy',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            )
          else
            GoogleMap(
              onMapCreated: (c) {
                _mapController = c;
                c.setMapStyle(darkMapStyle);
              },
              initialCameraPosition: CameraPosition(
                target: _path.first.toLatLng(),
                zoom: 17,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              polylines: _polylines,
            ),

          // ── LIVE badge ───────────────────────────────────
          if (hasLocation)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.danger.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'RECORDING',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Top nav ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _cancelWalk,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Prayer Walk',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ],
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // ── Error banner ─────────────────────────────────
          if (_error != null)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.danger.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 14)),
              ),
            ),

          // ── Stats bar ────────────────────────────────────
          Positioned(
            bottom: 110,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surface),
              ),
              child: Row(
                children: [
                  _WalkStat(
                    value: formatDuration(_duration),
                    label: 'Duration',
                  ),
                  const _Divider(),
                  _WalkStat(
                    value: formatDistance(_distance),
                    label: 'Distance',
                  ),
                  const _Divider(),
                  _WalkStat(
                    value: formatPace(_distance, _duration),
                    label: 'Pace',
                  ),
                ],
              ),
            ),
          ),

          // ── End button ───────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                      shadowColor: AppColors.danger.withOpacity(0.4),
                    ),
                    onPressed: _saving ? null : _endWalk,
                    child: _saving
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Saving…',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800)),
                            ],
                          )
                        : const Text(
                            'End Prayer Walk',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
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
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        color: AppColors.surface,
      );
}
