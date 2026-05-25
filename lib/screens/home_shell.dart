import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';
import '../widgets/community_walks_map.dart';
import '../widgets/walk_feed_card.dart';
import 'active_walk_screen.dart';
import 'group_screen.dart';
import 'profile_screen.dart';
import 'walk_preview_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0; // 0=Feed 1=Map 2=Community 3=Profile

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Capture provider references before any awaits to avoid
      // using BuildContext across async gaps.
      final auth = context.read<AuthProvider>();
      final walksProvider = context.read<WalksProvider>();
      final profileProvider = context.read<ProfileProvider>();
      final groupProvider = context.read<GroupProvider>();

      await walksProvider.fetchWalks();
      walksProvider.subscribeRealtime();

      if (auth.userId != null) {
        await profileProvider.fetchProfile(auth.userId!);
        final groupId = profileProvider.groupId;
        if (groupId != null) {
          await groupProvider.fetchGroup(groupId);
        }
      }
    });
  }

  void _startWalk() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveWalkScreen()),
    );
    if (mounted) context.read<WalksProvider>().fetchWalks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _FeedTab(),
          _MapTab(),
          GroupScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _PrayerWalkNavBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        onRecord: _startWalk,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Custom bottom nav bar with centre record button
// ────────────────────────────────────────────────────────────────────────────

class _PrayerWalkNavBar extends StatelessWidget {
  const _PrayerWalkNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onRecord,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      height: 72 + bottom,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Row(
          children: [
            _NavBtn(
              icon: Icons.home_rounded,
              outlineIcon: Icons.home_outlined,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavBtn(
              icon: Icons.map_rounded,
              outlineIcon: Icons.map_outlined,
              label: 'Map',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            // Centre record button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onRecord,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 34),
                  ),
                ),
              ),
            ),
            _NavBtn(
              icon: Icons.group_rounded,
              outlineIcon: Icons.group_outlined,
              label: 'Community',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _NavBtn(
              icon: Icons.person_rounded,
              outlineIcon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.outlineIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData outlineIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? icon : outlineIcon,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  size: 24,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Feed Tab
// ────────────────────────────────────────────────────────────────────────────

class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  WalkPeriod _period = WalkPeriod.allTime;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final walksProvider = context.watch<WalksProvider>();
    final walks = walksProvider.walksForPeriod(_period);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PrayerWalk',
                          style: GoogleFonts.dmSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'Community feed',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Period filter
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'All Time',
                    selected: _period == WalkPeriod.allTime,
                    onTap: () =>
                        setState(() => _period = WalkPeriod.allTime),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'This Week',
                    selected: _period == WalkPeriod.thisWeek,
                    onTap: () =>
                        setState(() => _period = WalkPeriod.thisWeek),
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Today',
                    selected: _period == WalkPeriod.today,
                    onTap: () =>
                        setState(() => _period = WalkPeriod.today),
                  ),
                ],
              ),
            ),
          ),

          if (walksProvider.fetchError != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.warning.withOpacity(0.35)),
                ),
                child: Text(walksProvider.fetchError!,
                    style: GoogleFonts.dmSans(
                        color: AppColors.warning, fontSize: 13)),
              ),
            ),

          // Walk list
          Expanded(
            child: walksProvider.loading && walks.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onRefresh: () =>
                        context.read<WalksProvider>().fetchWalks(),
                    child: walks.isEmpty
                        ? _EmptyFeed()
                        : ListView.separated(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: walks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (ctx, i) {
                              final w = walks[i];
                              return WalkFeedCard(
                                walk: w,
                                isOwnWalk: w.userId == auth.userId,
                                onTap: w.path.length < 2
                                    ? null
                                    : () => Navigator.push(
                                          ctx,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                WalkPreviewScreen(walk: w),
                                          ),
                                        ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                Text(
                  'No walks yet',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to start a prayer walk\nin Nottingham.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ────────────────────────────────────────────────────────────────────────────
// Map Tab
// ────────────────────────────────────────────────────────────────────────────

class _MapTab extends StatefulWidget {
  const _MapTab();

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  WalkPeriod _period = WalkPeriod.allTime;
  String? _highlightUserId;

  @override
  Widget build(BuildContext context) {
    final walksProvider = context.watch<WalksProvider>();
    final auth = context.read<AuthProvider>();
    final walks = walksProvider.walksForPeriod(_period);

    final totalDist = walks.fold<double>(0, (a, w) => a + w.distance);

    return Stack(
      children: [
        // Full-screen map
        Positioned.fill(
          child: CommunityWalksMap(
            walks: walks,
            highlightUserId: _highlightUserId,
          ),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.border.withOpacity(0.7)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.self_improvement_rounded,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Nottingham Prayer Walks',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${walks.length} routes',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Period filter chips
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _MapChip(
                          label: 'All Time',
                          selected: _period == WalkPeriod.allTime,
                          onTap: () =>
                              setState(() => _period = WalkPeriod.allTime),
                        ),
                        const SizedBox(width: 6),
                        _MapChip(
                          label: 'This Week',
                          selected: _period == WalkPeriod.thisWeek,
                          onTap: () => setState(
                              () => _period = WalkPeriod.thisWeek),
                        ),
                        const SizedBox(width: 6),
                        _MapChip(
                          label: 'Today',
                          selected: _period == WalkPeriod.today,
                          onTap: () =>
                              setState(() => _period = WalkPeriod.today),
                        ),
                        const SizedBox(width: 6),
                        _MapChip(
                          label: 'My Walks',
                          selected:
                              _highlightUserId == auth.userId,
                          onTap: () => setState(() {
                            _highlightUserId =
                                _highlightUserId == auth.userId
                                    ? null
                                    : auth.userId;
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom stats overlay
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.border.withOpacity(0.7)),
              ),
              child: Row(
                children: [
                  _MapStat(
                      value: '${walks.length}',
                      label: 'Routes',
                      color: AppColors.primary),
                  Container(
                      width: 1,
                      height: 32,
                      color: AppColors.border,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16)),
                  _MapStat(
                    value: formatDistance(totalDist),
                    label: 'Community km',
                    color: AppColors.success,
                  ),
                  if (_highlightUserId != null) ...[
                    Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 16)),
                    _MapStat(
                      value:
                          '${walksProvider.walksForUser(_highlightUserId!).length}',
                      label: 'My routes',
                      color: AppColors.info,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapStat extends StatelessWidget {
  const _MapStat(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: GoogleFonts.dmSans(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              )),
          Text(label,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              )),
        ],
      );
}

class _MapChip extends StatelessWidget {
  const _MapChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.background.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border.withOpacity(0.8),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      );
}
