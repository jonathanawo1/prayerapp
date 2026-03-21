import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/map_style.dart';
import '../providers/auth_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';
import 'active_walk_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _locationLoading = true;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final walks = context.read<WalksProvider>();
    await walks.fetchWalks();
    walks.subscribeRealtime();
    await _startLocationWatch();
  }

  Future<void> _startLocationWatch() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _locationLoading = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
          _locationLoading = false;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15),
        );
      }
    } catch (_) {
      setState(() => _locationLoading = false);
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(
            () => _currentLocation = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Polyline> _buildPolylines(List walks) {
    return walks.asMap().entries.map((entry) {
      final walk = entry.value;
      return Polyline(
        polylineId: PolylineId(walk.id),
        points: walk.path.map((c) => c.toLatLng()).toList(),
        color: AppColors.success,
        width: 4,
        jointType: JointType.round,
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final walksProvider = context.watch<WalksProvider>();
    final walks = walksProvider.walks;

    final totalMeters =
        walks.fold<double>(0, (acc, w) => acc + w.distance);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────
          if (_locationLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Finding your location…',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
                controller.setMapStyle(darkMapStyle);
                if (_currentLocation != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentLocation!, 15),
                  );
                }
              },
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(51.5074, -0.1278),
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              polylines: _buildPolylines(walks),
            ),

          // ── Top header ───────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Prayer Walk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Covering the earth together',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            auth.userEmail?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats widget ─────────────────────────────────
          Positioned(
            top: 120,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.success.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  _StatItem(
                    value: '${walks.length}',
                    label: 'Walks',
                    color: AppColors.success,
                  ),
                  const SizedBox(
                    height: 1,
                    width: 60,
                    child: ColoredBox(color: AppColors.surface),
                  ).withPadding(const EdgeInsets.symmetric(vertical: 8)),
                  _StatItem(
                    value: formatDistance(totalMeters),
                    label: 'Covered',
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ───────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 8,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ActiveWalkScreen()),
                        ).then((_) => walksProvider.fetchWalks()),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🙏', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Text(
                              'Start Prayer Walk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await auth.signOut();
                        // Auth gate in main.dart re-routes to AuthScreen automatically
                      },
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
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


class _StatItem extends StatelessWidget {
  const _StatItem(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
}

extension on Widget {
  Widget withPadding(EdgeInsets padding) =>
      Padding(padding: padding, child: this);
}
