import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';
import '../models/walk.dart';
import '../utils/distance.dart';
import '../widgets/community_walks_map.dart';

/// Full-screen interactive preview of a completed walk with bottom details sheet.
class WalkPreviewScreen extends StatelessWidget {
  const WalkPreviewScreen({super.key, required this.walk});

  final Walk walk;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map fills the screen
          Positioned.fill(
            child: CommunityWalksMap(
              walks: [walk],
              highlightUserId: walk.userId,
            ),
          ),

          // Back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary, size: 18),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Details bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title + walker
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.routeColorForUser(walk.userId)
                                  .withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                walk.walkerName[0].toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  color: AppColors.routeColorForUser(
                                      walk.userId),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  walk.title?.isNotEmpty == true
                                      ? walk.title!
                                      : 'Prayer Walk',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  walk.walkerName,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        children: [
                          _DetailStat(
                            icon: Icons.straighten_rounded,
                            value: formatDistance(walk.distance),
                            label: 'Distance',
                          ),
                          _DetailStat(
                            icon: Icons.timer_outlined,
                            value: formatDuration(walk.duration),
                            label: 'Duration',
                          ),
                          _DetailStat(
                            icon: Icons.speed_rounded,
                            value: formatPace(walk.distance, walk.duration),
                            label: 'Pace',
                          ),
                        ],
                      ),

                      if (walk.prayerNotes != null &&
                          walk.prayerNotes!.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🙏',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  walk.prayerNotes!,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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

class _DetailStat extends StatelessWidget {
  const _DetailStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(value,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    )),
              ],
            ),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
}
