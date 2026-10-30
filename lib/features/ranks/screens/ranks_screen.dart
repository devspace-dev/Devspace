import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../models/user_model.dart';
import '../../../screens/profile_screen.dart';
import '../../../services/supabase_service.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  bool _isMonthly = true;
  bool _isCollege = true;
  List<UserModel>? _remoteLeaderboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UsersProvider>().fetchUsers();
        _fetchLeaderboard();
      }
    });
  }

  Future<void> _fetchLeaderboard() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final collegeFilter = _isCollege && (me?.college.isNotEmpty ?? false) ? me!.college : null;
    try {
      final list = _isMonthly
          ? await SupabaseService.instance.getMonthlyAuraLeaderboard(college: collegeFilter)
          : await SupabaseService.instance.getAllTimeAuraLeaderboard(college: collegeFilter);
      if (mounted && list.isNotEmpty) {
        setState(() => _remoteLeaderboard = list);
      }
    } catch (_) {
      // Keep local in-memory fallback
    }
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  static String getRankTag(int aura) {
    if (aura >= 5000) return '10x Dev';
    if (aura >= 1500) return 'SO Survivor';
    if (aura >= 500) return 'Bug Hunter';
    return 'Rookie';
  }

  static Color getTierColor(int aura) {
    if (aura >= 5000) return Ds.tierGem;
    if (aura >= 1500) return Ds.tierGold;
    if (aura >= 500) return Ds.tierSilver;
    return Ds.tierBronze;
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final usersP = context.watch<UsersProvider>();
    
    List<UserModel> localUsers = List<UserModel>.from(usersP.users);
    if (_isCollege && me != null && me.college.isNotEmpty) {
      final collegeUsers = localUsers
          .where((u) => u.college.toLowerCase().trim() == me.college.toLowerCase().trim())
          .toList();
      if (collegeUsers.isNotEmpty) {
        localUsers = collegeUsers;
      }
    }
    localUsers.sort((a, b) => b.aura.compareTo(a.aura));

    List<UserModel> users;
    if (_remoteLeaderboard != null) {
      users = _remoteLeaderboard!.map((u) {
        if (me != null && u.id == me.id && u.aura != me.aura) {
          return u.copyWith(aura: me.aura);
        }
        return u;
      }).toList();
    } else {
      users = localUsers;
    }

    final hasData = users.isNotEmpty && users.any((u) => u.aura > 0);
    final myRank = me != null ? users.indexWhere((u) => u.id == me.id) + 1 : 0;
    final collegeName = (me?.college.isNotEmpty ?? false)
        ? me!.college.split(' ').first
        : 'Your College';

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('RANKS', style: DsText.h2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: AuraChip(me?.aura ?? 0),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Ds.aura,
        backgroundColor: Ds.surface,
        onRefresh: () async {
          await context.read<UsersProvider>().fetchUsers();
          await _fetchLeaderboard();
        },
        child: CustomScrollView(
        slivers: [
          // Filter toggles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildPill(
                        label: 'MONTHLY',
                        active: _isMonthly,
                        onTap: () {
                          setState(() {
                            _isMonthly = true;
                            _remoteLeaderboard = null;
                          });
                          _fetchLeaderboard();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildPill(
                        label: 'ALL TIME',
                        active: !_isMonthly,
                        onTap: () {
                          setState(() {
                            _isMonthly = false;
                            _remoteLeaderboard = null;
                          });
                          _fetchLeaderboard();
                        },
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isCollege = !_isCollege;
                        _remoteLeaderboard = null;
                      });
                      _fetchLeaderboard();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Ds.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Ds.border),
                      ),
                      child: Text(
                        _isCollege ? 'COLLEGE' : 'GLOBAL',
                        style: DsText.caption.copyWith(color: Ds.aura, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // College Rivalry Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: DsCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$collegeName vs Apex Tech', style: DsText.label),
                        Text('+140 AURA', style: DsText.number.copyWith(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: const SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 65,
                              child: ColoredBox(color: Ds.aura),
                            ),
                            Expanded(
                              flex: 35,
                              child: ColoredBox(color: Ds.hot),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You are 140 Aura ahead. Do not get cooked.',
                      style: DsText.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (usersP.isLoading && users.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Ds.aura),
              ),
            )
          else if (!hasData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 64, color: Ds.muted),
                      const SizedBox(height: 16),
                      Text('Season just started.', style: DsText.h3),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first on the board.',
                        style: DsText.bodySm.copyWith(color: Ds.muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            // Top 3 Podium
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: _buildPodium(users),
              ),
            ),

            // Ranks 4+
            if (users.length > 3)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final userIndex = index + 3;
                      final u = users[userIndex];
                      final isMe = me?.id == u.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildRankRow(
                          rank: userIndex + 1,
                          user: u,
                          isMe: isMe,
                        ),
                      );
                    },
                    childCount: users.length - 3,
                  ),
                ),
              )
            else
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
          ],
        ],
      ),
    ),
      bottomSheet: me != null && myRank > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Ds.navBg,
                border: Border(
                  top: BorderSide(color: Ds.aura, width: 2),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Text(
                      '#$myRank',
                      style: DsText.h3.copyWith(color: Ds.aura),
                    ),
                    const SizedBox(width: 14),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Ds.surface,
                      child: Text(
                        me.name.isNotEmpty ? me.name[0].toUpperCase() : 'U',
                        style: DsText.caption.copyWith(color: Ds.bone),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  me.name,
                                  style: DsText.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const DsTag('YOU', bg: Ds.aura, fg: Ds.ink),
                            ],
                          ),
                          Text('@${me.handle}', style: DsText.caption),
                        ],
                      ),
                    ),
                    Text(
                      '${me.aura} AURA',
                      style: DsText.number.copyWith(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPill({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Ds.aura : Ds.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? Ds.auraEdge : Ds.border),
        ),
        child: Text(
          label,
          style: DsText.caption.copyWith(
            color: active ? Ds.onAura : Ds.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<UserModel> users) {
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Left)
        Expanded(
          child: _buildPodiumColumn(
            user: second,
            rank: 2,
            podiumHeight: 80,
            ringColor: Ds.tierSilver,
            rankNumberStyle: DsText.h2.copyWith(color: Ds.tierSilver),
          ),
        ),
        const SizedBox(width: 10),

        // 1st Place (Center - Highest)
        Expanded(
          child: _buildPodiumColumn(
            user: first,
            rank: 1,
            podiumHeight: 110,
            ringColor: Ds.aura,
            rankNumberStyle: DsText.h1.copyWith(color: Ds.aura, fontSize: 36),
            isFirst: true,
          ),
        ),
        const SizedBox(width: 10),

        // 3rd Place (Right)
        Expanded(
          child: _buildPodiumColumn(
            user: third,
            rank: 3,
            podiumHeight: 60,
            ringColor: Ds.tierBronze,
            rankNumberStyle: DsText.h3.copyWith(color: Ds.tierBronze),
          ),
        ),
      ],
    );
  }

  Widget _buildPodiumColumn({
    required UserModel? user,
    required int rank,
    required double podiumHeight,
    required Color ringColor,
    required TextStyle rankNumberStyle,
    bool isFirst = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user != null) ...[
          GestureDetector(
            onTap: () => _openProfile(user.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirst)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Icon(Icons.workspace_premium_rounded, color: Ds.aura, size: 24),
                  ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: isFirst ? 26 : 22,
                    backgroundColor: Ds.surface,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: DsText.h3.copyWith(
                        color: Ds.bone,
                        fontSize: isFirst ? 20 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.name.split(' ').first,
                  style: DsText.label.copyWith(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${user.aura}',
                  style: DsText.number.copyWith(
                    fontSize: isFirst ? 16 : 14,
                    color: isFirst ? Ds.aura : Ds.bone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const CircleAvatar(
            radius: 20,
            backgroundColor: Ds.surface,
            child: Icon(Icons.person_outline_rounded, color: Ds.muted, size: 20),
          ),
          const SizedBox(height: 6),
          Text('--', style: DsText.caption),
          const SizedBox(height: 8),
        ],

        // Podium Block
        Container(
          height: podiumHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Ds.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: ringColor, width: 2),
          ),
          alignment: Alignment.center,
          child: Text('$rank', style: rankNumberStyle),
        ),
      ],
    );
  }

  Widget _buildRankRow({
    required int rank,
    required UserModel user,
    required bool isMe,
  }) {
    final tierColor = getTierColor(user.aura);
    final rankTag = getRankTag(user.aura);

    return DsCard(
      borderColor: isMe ? Ds.aura : Ds.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onTap: () => _openProfile(user.id),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: DsText.h3.copyWith(
                color: Ds.muted,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: Ds.surface,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: DsText.caption.copyWith(color: Ds.bone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.name,
                        style: DsText.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    DsTag(rankTag, bg: tierColor, fg: Ds.ink),
                  ],
                ),
                Text(
                  '@${user.handle}',
                  style: DsText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '${user.aura}',
            style: DsText.number.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
