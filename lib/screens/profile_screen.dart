import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editingName = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final userId = context.read<AuthProvider>().userId!;
    final ok = await context.read<ProfileProvider>().updateDisplayName(
          userId,
          name,
        );
    if (ok && mounted) setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final walksProvider = context.watch<WalksProvider>();
    final group = context.watch<GroupProvider>().group;

    final allWalks = walksProvider.walks;
    final myWalks =
        allWalks.where((w) => w.userId == auth.userId).toList();

    final totalDist = myWalks.fold<double>(0, (a, w) => a + w.distance);
    final totalSecs = myWalks.fold<int>(0, (a, w) => a + w.duration);
    final longest = myWalks.isEmpty
        ? 0.0
        : myWalks.map((w) => w.distance).reduce((a, b) => a > b ? a : b);

    final displayName = profile.displayName;
    final initials = profile.profile?.initials ?? 'P';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          // ── Avatar hero ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.background,
                ],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Display name (editable)
                if (_editingName)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextFormField(
                          controller: _nameCtrl,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onFieldSubmitted: (_) => _saveDisplayName(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _saveDisplayName,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: AppColors.success, size: 18),
                        ),
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () {
                      _nameCtrl.text = displayName;
                      setState(() => _editingName = true);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.edit_rounded,
                            color: AppColors.textMuted, size: 16),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),
                Text(
                  auth.userEmail ?? '',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Chip(
                      icon: Icons.self_improvement_rounded,
                      label: 'Prayer Walker',
                      color: AppColors.primary,
                    ),
                    if (group != null) ...[
                      const SizedBox(width: 8),
                      _Chip(
                        icon: Icons.group_rounded,
                        label: group.name,
                        color: AppColors.info,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Stats grid ────────────────────────────────────────
          _SectionHeader('My Journey'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatCard(
                    label: 'Walks',
                    value: '${myWalks.length}',
                    color: AppColors.primary),
                _StatCard(
                    label: 'Distance',
                    value: formatDistance(totalDist),
                    color: AppColors.success),
                _StatCard(
                    label: 'Time Walking',
                    value: formatDuration(totalSecs),
                    color: AppColors.warning),
                _StatCard(
                    label: 'Longest Walk',
                    value: formatDistance(longest),
                    color: const Color(0xFFEC4899)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Recent walks ──────────────────────────────────────
          if (myWalks.isNotEmpty) ...[
            _SectionHeader('Recent Walks'),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: myWalks.length.clamp(0, 10),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                final w = myWalks[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: GoogleFonts.dmSans(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.title?.isNotEmpty == true
                                  ? w.title!
                                  : 'Prayer Walk',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${formatDistance(w.distance)} · '
                              '${formatDuration(w.duration)} · '
                              '${_formatDate(w.endTime)}',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
          ],

          if (myWalks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 40, horizontal: 40),
              child: Column(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text('No walks yet',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    'Start your first prayer walk to see your journey here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ],
              ),
            ),

          // ── Sign out ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 52),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('Sign Out',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              onPressed: () async {
                context.read<GroupProvider>().clear();
                context.read<ProfileProvider>().clear();
                await context.read<AuthProvider>().signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
        child: Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 42) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );
}
