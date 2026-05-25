import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../core/theme.dart';
import '../models/walk.dart';
import '../utils/distance.dart';
import '../utils/mapbox_static_preview.dart';

/// Strava-style activity card for the PrayerWalk community feed.
class WalkFeedCard extends StatelessWidget {
  const WalkFeedCard({
    super.key,
    required this.walk,
    required this.isOwnWalk,
    this.onTap,
  });

  final Walk walk;
  final bool isOwnWalk;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final previewUrl = MapboxStaticPreview.urlForWalk(walk);
    final routeColor = AppColors.routeColorForUser(walk.userId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(walk: walk, isOwnWalk: isOwnWalk, routeColor: routeColor),
            _MapPreview(previewUrl: previewUrl, routeColor: routeColor),
            _StatsRow(walk: walk),
            if (walk.prayerNotes != null && walk.prayerNotes!.isNotEmpty)
              _PrayerNotesSnippet(notes: walk.prayerNotes!),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.walk,
    required this.isOwnWalk,
    required this.routeColor,
  });

  final Walk walk;
  final bool isOwnWalk;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    final name = walk.walkerName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: routeColor.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: routeColor.withOpacity(0.5), width: 1.5),
            ),
            child: Center(
              child: Text(
                initial,
                style: GoogleFonts.dmSans(
                  color: routeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (isOwnWalk) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.dmSans(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      walk.title?.isNotEmpty == true
                          ? walk.title!
                          : 'Prayer Walk',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '  ·  ${timeago.format(walk.endTime.toLocal())}',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.previewUrl, required this.routeColor});
  final String? previewUrl;
  final Color routeColor;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: previewUrl == null
          ? Container(
              color: AppColors.surfaceAlt,
              child: Center(
                child: Icon(Icons.map_outlined,
                    color: AppColors.textMuted, size: 36),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  previewUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(color: AppColors.surfaceAlt);
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.textMuted),
                  ),
                ),
                // Subtle route-colour gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.surface.withOpacity(0.7),
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.walk});
  final Walk walk;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _Stat(
            icon: Icons.straighten_rounded,
            value: formatDistance(walk.distance),
            label: 'Distance',
          ),
          _Stat(
            icon: Icons.timer_outlined,
            value: formatDuration(walk.duration),
            label: 'Duration',
          ),
          _Stat(
            icon: Icons.speed_rounded,
            value: formatPace(walk.distance, walk.duration),
            label: 'Pace',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
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
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _PrayerNotesSnippet extends StatelessWidget {
  const _PrayerNotesSnippet({required this.notes});
  final String notes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🙏', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notes,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
