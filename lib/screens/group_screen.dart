import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/group.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/walks_provider.dart';
import '../utils/distance.dart';

/// Community tab: shows the group the user belongs to, or lets them join/create one.
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroup());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final profile = context.read<ProfileProvider>().profile;
    if (profile?.groupId != null) {
      await context.read<GroupProvider>().fetchGroup(profile!.groupId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final groups = context.watch<GroupProvider>();

    final hasGroup = profile.hasGroup && groups.group != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: hasGroup
          ? _GroupView(tabs: _tabs)
          : _NoGroupView(onJoined: _loadGroup),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Group view (user is in a group)
// ────────────────────────────────────────────────────────────────────────────

class _GroupView extends StatelessWidget {
  const _GroupView({required this.tabs});
  final TabController tabs;

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupProvider>();
    final group = groups.group!;

    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverToBoxAdapter(child: _GroupHeader(group: group)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: tabs,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [Tab(text: 'Members'), Tab(text: 'Stats')],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: tabs,
        children: [
          _MembersList(members: groups.members),
          _GroupStats(group: group),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.group_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty)
                      Text(
                        group.description!,
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
          // Invite code chip
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: group.inviteCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded,
                      color: AppColors.textSecondary, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    'Invite code: ',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    group.inviteCode,
                    style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  const _MembersList({required this.members});
  final List members;

  @override
  Widget build(BuildContext context) {
    final walks = context.watch<WalksProvider>().walks;

    if (members.isEmpty) {
      return const Center(
        child: Text('No members yet.',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final member = members[i];
        final memberWalks =
            walks.where((w) => w.userId == member.id).toList();
        final totalDist = memberWalks.fold<double>(
            0, (acc, w) => acc + w.distance);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                      member.nameOrFallback,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${memberWalks.length} walks · ${formatDistance(totalDist)}',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms);
      },
    );
  }
}

class _GroupStats extends StatelessWidget {
  const _GroupStats({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    final walks = context.watch<WalksProvider>().walks;
    final totalDist = walks.fold<double>(0, (a, w) => a + w.distance);
    final totalSecs = walks.fold<int>(0, (a, w) => a + w.duration);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatTile(label: 'Total walks', value: '${walks.length}',
            icon: Icons.directions_walk_rounded, color: AppColors.primary),
        const SizedBox(height: 10),
        _StatTile(label: 'Total distance', value: formatDistance(totalDist),
            icon: Icons.straighten_rounded, color: AppColors.success),
        const SizedBox(height: 10),
        _StatTile(label: 'Total time', value: formatDuration(totalSecs),
            icon: Icons.timer_outlined, color: AppColors.info),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 14)),
            ),
            Text(value,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                )),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────────────────────
// No-group view: join or create
// ────────────────────────────────────────────────────────────────────────────

class _NoGroupView extends StatefulWidget {
  const _NoGroupView({required this.onJoined});
  final VoidCallback onJoined;

  @override
  State<_NoGroupView> createState() => _NoGroupViewState();
}

class _NoGroupViewState extends State<_NoGroupView> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _showCreate = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    final groups = context.read<GroupProvider>();
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();

    final group = await groups.joinByInviteCode(_codeCtrl.text);
    if (!mounted) return;
    if (group == null) return; // error shown in UI
    await profile.updateGroupId(auth.userId!, group.id);
    widget.onJoined();
  }

  Future<void> _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final groups = context.read<GroupProvider>();
    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();

    final group = await groups.createGroup(
      name: _nameCtrl.text,
      description: _descCtrl.text,
      createdBy: auth.userId!,
    );
    if (!mounted) return;
    if (group == null) return;
    await profile.updateGroupId(auth.userId!, group.id);
    widget.onJoined();
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.2),
                    AppColors.surface
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.4), width: 2),
              ),
              child: const Icon(Icons.group_add_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text('Join your prayer group',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 8),
            Text(
              'Enter an invite code from your group leader, or create a new prayer group.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),

            if (!_showCreate) ...[
              _Label('Invite Code'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
                decoration: const InputDecoration(
                  hintText: 'ABC123',
                ),
                maxLength: 6,
              ),
              if (groups.error != null) ...[
                const SizedBox(height: 8),
                Text(groups.error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: groups.loading ? null : _joinGroup,
                  child: groups.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Join Group',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  groups.clearError();
                  setState(() => _showCreate = true);
                },
                child: Text(
                  'Create a new prayer group',
                  style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ] else ...[
              _Label('Group Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration:
                    const InputDecoration(hintText: 'Nottingham Prayer Walkers'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              _Label('Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                    hintText: 'Walking in prayer across the city'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              if (groups.error != null) ...[
                const SizedBox(height: 8),
                Text(groups.error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: groups.loading ? null : _createGroup,
                  child: groups.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Create Group',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showCreate = false),
                child: Text('Back to join',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      );
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(_, __, ___) => ColoredBox(
        color: AppColors.background,
        child: Column(
          children: [
            tabBar,
            Container(height: 1, color: AppColors.border),
          ],
        ),
      );

  @override
  bool shouldRebuild(_) => false;
}
