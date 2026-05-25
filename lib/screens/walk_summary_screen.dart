import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/walk_draft.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';
import '../utils/mapbox_static_preview.dart';

/// Post-walk summary: shows stats, lets the user add a title and prayer notes,
/// then saves the walk to Supabase.
class WalkSummaryScreen extends StatefulWidget {
  const WalkSummaryScreen({super.key, required this.draft});

  final WalkDraft draft;

  @override
  State<WalkSummaryScreen> createState() => _WalkSummaryScreenState();
}

class _WalkSummaryScreenState extends State<WalkSummaryScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final userId = context.read<AuthProvider>().userId!;
      final groupId = context.read<ProfileProvider>().groupId;
      await context.read<WalksProvider>().saveWalk(
            userId: userId,
            path: List.from(widget.draft.path),
            distance: widget.draft.distance,
            duration: widget.draft.duration,
            startTime: widget.draft.startTime,
            endTime: widget.draft.endTime,
            title: _titleCtrl.text.trim().isEmpty
                ? null
                : _titleCtrl.text.trim(),
            prayerNotes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            groupId: groupId,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save walk. Please try again.';
      });
    }
  }

  void _discard() {
    Navigator.of(context).pop();
  }

  String? _previewUrl() {
    // Build a temporary Walk-like object using the draft for the static preview
    // We can reuse MapboxStaticPreview by building a mini walk representation
    if (widget.draft.path.length < 2) return null;
    return MapboxStaticPreview.urlForPath(widget.draft.path);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final previewUrl = _previewUrl();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _discard,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.close,
                            color: AppColors.textSecondary, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Prayer Walk Complete',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              // ── Stats hero ────────────────────────────────────
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '🙏',
                      style: const TextStyle(fontSize: 40),
                    ).animate().scale(
                          delay: 100.ms,
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'Great walk!',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _HeroStat(
                          value: formatDistance(d.distance),
                          label: 'Distance',
                          color: AppColors.primary,
                        ),
                        _HeroStat(
                          value: formatDuration(d.duration),
                          label: 'Duration',
                          color: AppColors.success,
                        ),
                        _HeroStat(
                          value: formatPace(d.distance, d.duration),
                          label: 'Pace',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 16),

              // ── Map preview ───────────────────────────────────
              if (previewUrl != null)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      previewUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(Icons.map_outlined,
                              color: AppColors.textMuted, size: 40),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── Title input ───────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Walk Title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Morning walk around the city',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    _Label('Prayer Notes'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText:
                            'What did you pray for on this walk?',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.danger.withOpacity(0.3)),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 14)),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Actions ───────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  children: [
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : Text('Save Walk',
                                style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : _discard,
                      child: Text(
                        'Discard walk',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      );
}
