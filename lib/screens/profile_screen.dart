import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final walks = context.watch<WalksProvider>().walks;
    final myWalks =
        walks.where((w) => w.userId == auth.userId).toList();

    final totalMeters =
        myWalks.fold<double>(0, (acc, w) => acc + w.distance);
    final totalSecs = myWalks.fold<int>(0, (acc, w) => acc + w.duration);
    final longest = myWalks.isEmpty
        ? 0.0
        : myWalks
            .map((w) => w.distance)
            .reduce((a, b) => a > b ? a : b);
    final avg = myWalks.isEmpty ? 0.0 : totalMeters / myWalks.length;

    final initial = auth.userEmail?[0].toUpperCase() ?? 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.surface),
        ),
      ),
      body: ListView(
        children: [
          // ── Avatar + identity ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  auth.userEmail ?? '',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Prayer Walker',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── My stats grid ─────────────────────────────────
          _SectionHeader('My Journey'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatCard(
                    label: 'Total Walks',
                    value: '${myWalks.length}',
                    accent: AppColors.primary),
                _StatCard(
                    label: 'Distance',
                    value: formatDistance(totalMeters),
                    accent: AppColors.success),
                _StatCard(
                    label: 'Time Walking',
                    value: formatDuration(totalSecs),
                    accent: AppColors.warning),
                _StatCard(
                    label: 'Longest Walk',
                    value: formatDistance(longest),
                    accent: const Color(0xFFEC4899)),
                _StatCard(
                    label: 'Avg. Distance',
                    value: formatDistance(avg),
                    accent: const Color(0xFF06B6D4)),
                _StatCard(
                    label: 'Global Walks',
                    value: '${walks.length}',
                    accent: const Color(0xFF8B5CF6)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Recent walks ──────────────────────────────────
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
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
                              formatDistance(w.distance),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${formatDuration(w.duration)} · '
                              '${_formatDate(w.createdAt)}',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${w.path.length} pts',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
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
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
              child: Column(
                children: const [
                  Text('🗺️', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('No walks yet',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text(
                    'Start your first prayer walk to see your stats here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

          // ── Sign out ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
                // Auth gate in main.dart automatically reroutes to AuthScreen
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Sign Out',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.accent});
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 42) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accent,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
