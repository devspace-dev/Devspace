import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/aura_chip.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/users_provider.dart';
import '../../../models/user_model.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../services/supabase_service.dart';
import '../../tour/models/tour_step.dart';
import '../../tour/widgets/tour_anchor.dart';

typedef LeaderboardLoader = Future<List<UserModel>> Function({
  required bool isMonthly,
  String? college,
});

class RanksScreen extends StatefulWidget {
  const RanksScreen({
    super.key,
    this.leaderboardLoader,
  });

  final LeaderboardLoader? leaderboardLoader;

  /// Computes 1-based standard competition ranks (1, 2, 2, 4) for a
  /// descending-sorted list of positive-aura users.
  static List<int> computeCompetitionRanks(List<UserModel> users) {
    final ranks = <int>[];
    for (var i = 0; i < users.length; i++) {
      if (i == 0) {
        ranks.add(1);
      } else if (users[i].aura == users[i - 1].aura) {
        ranks.add(ranks[i - 1]);
      } else {
        ranks.add(i + 1);
      }
    }
    return ranks;
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
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> with WidgetsBindingObserver {
  bool _isMonthly = true;
  bool _isCollege = true;
  List<UserModel>? _remoteLeaderboard;
  bool _hasRemoteData = false;
  bool _isLoadingRemote = false;
  String? _remoteError;
  ({int? rank, int aura, bool outsideTop100})? _myRankFallback;

  bool _initializedTabState = false;
  bool _wasTabActive = true;
  int? _lastObservedUserAura;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UsersProvider>().fetchUsers();
        _fetchLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchLeaderboard();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTabActive = TickerMode.valuesOf(context).enabled;
    if (!_initializedTabState) {
      _initializedTabState = true;
      _wasTabActive = isTabActive;
    } else if (isTabActive && !_wasTabActive) {
      _wasTabActive = true;
      _fetchLeaderboard();
    } else if (!isTabActive) {
      _wasTabActive = false;
    }

    final meAura = context.read<AuthProvider>().currentUserOrNull?.aura;
    if (_lastObservedUserAura != null &&
        meAura != null &&
        meAura != _lastObservedUserAura) {
      _lastObservedUserAura = meAura;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fetchLeaderboard();
      });
    } else if (_lastObservedUserAura == null && meAura != null) {
      _lastObservedUserAura = meAura;
    }
  }

  String? _effectiveCollegeFilter(UserModel? me) {
    final college = me?.college.trim() ?? '';
    if (!_isCollege || college.isEmpty) return null;
    return me!.college;
  }

  Future<void> _fetchLeaderboard() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final collegeFilter = _effectiveCollegeFilter(me);
    final isMonthly = _isMonthly;

    final hasCustomLoader = widget.leaderboardLoader != null;
    final useSupabase =
        hasCustomLoader || SupabaseService.instance.isSupabaseReady;

    if (!useSupabase) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingRemote = true;
        _remoteError = null;
      });
    }

    try {
      final list = hasCustomLoader
          ? await widget.leaderboardLoader!(
              isMonthly: isMonthly,
              college: collegeFilter,
            )
          : (isMonthly
              ? await SupabaseService.instance.getMonthlyAuraLeaderboard(
                  college: collegeFilter,
                  throwOnError: true,
                )
              : await SupabaseService.instance.getAllTimeAuraLeaderboard(
                  college: collegeFilter,
                  throwOnError: true,
                ));

      ({int? rank, int aura, bool outsideTop100})? fallbackRank;
      if (me != null && !hasCustomLoader) {
        final inPositiveList =
            list.any((u) => u.id == me.id && u.aura > 0);
        if (!inPositiveList) {
          fallbackRank = await _resolveFallbackRankForMe(
            me: me,
            collegeFilter: collegeFilter,
            isMonthly: isMonthly,
            returnedCount: list.length,
          );
        }
      }

      if (!mounted) return;
      final currentMe = context.read<AuthProvider>().currentUserOrNull;
      if (isMonthly != _isMonthly ||
          collegeFilter != _effectiveCollegeFilter(currentMe)) {
        return;
      }

      setState(() {
        _remoteLeaderboard = list;
        _hasRemoteData = true;
        _isLoadingRemote = false;
        _remoteError = null;
        _myRankFallback = fallbackRank;
      });
    } catch (e) {
      debugPrint('Failed to load leaderboard: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingRemote = false;
        if (!_hasRemoteData) {
          _remoteError = 'Could not load rankings. Please try again.';
        }
      });
    }
  }

  Future<({int? rank, int aura, bool outsideTop100})> _resolveFallbackRankForMe({
    required UserModel me,
    required String? collegeFilter,
    required bool isMonthly,
    required int returnedCount,
  }) async {
    final rpcRank = await SupabaseService.instance.getMyLeaderboardRank(
      college: collegeFilter,
      isMonthly: isMonthly,
    );
    if (rpcRank != null) {
      return (
        rank: rpcRank.rank,
        aura: rpcRank.aura,
        outsideTop100: false,
      );
    }

    if (!isMonthly) {
      final rank = collegeFilter != null
          ? await SupabaseService.instance.getUserCollegeRank(me.id)
          : await SupabaseService.instance.getUserGlobalRank(me.id);
      return (
        rank: rank,
        aura: me.aura > 0 ? me.aura : 0,
        outsideTop100: false,
      );
    }

    final monthlyAura =
        await SupabaseService.instance.getMyCurrentMonthUtcAura(me.id);
    if (monthlyAura <= 0) {
      return (rank: null, aura: 0, outsideTop100: false);
    }
    return (
      rank: null,
      aura: monthlyAura,
      outsideTop100: returnedCount >= 100,
    );
  }

  void _openProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  String _currentUtcMonthLabel() {
    final utcNow = DateTime.now().toUtc();
    return '${_monthNames[utcNow.month - 1]} ${utcNow.year} (UTC)';
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    final usersP = context.watch<UsersProvider>();
    final myCollege = me?.college ?? '';
    final hasCollege = myCollege.trim().isNotEmpty;
    final isCollegeScopeActive = _isCollege && hasCollege;

    List<UserModel> sourceUsers;
    if (_hasRemoteData && _remoteLeaderboard != null) {
      sourceUsers = _remoteLeaderboard!;
    } else if (!SupabaseService.instance.isSupabaseReady &&
        widget.leaderboardLoader == null) {
      var localUsers = List<UserModel>.from(usersP.users);
      if (isCollegeScopeActive) {
        final collegeUsers = localUsers
            .where((u) =>
                u.college.toLowerCase().trim() ==
                myCollege.toLowerCase().trim())
            .toList();
        if (collegeUsers.isNotEmpty) {
          localUsers = collegeUsers;
        }
      }
      localUsers.sort((a, b) => b.aura.compareTo(a.aura));
      sourceUsers = localUsers;
    } else {
      sourceUsers = const [];
    }

    // Never rank or render 0-Aura rows.
    final rankedUsers = sourceUsers.where((u) => u.aura > 0).toList();
    final ranks = RanksScreen.computeCompetitionRanks(rankedUsers);
    final hasData = rankedUsers.isNotEmpty;

    final myIndex =
        me != null ? rankedUsers.indexWhere((u) => u.id == me.id) : -1;
    final String myRankLabel;
    final int myBoardAura;
    if (myIndex != -1) {
      myRankLabel = '#${ranks[myIndex]}';
      myBoardAura = rankedUsers[myIndex].aura;
    } else if (_myRankFallback != null) {
      if (_myRankFallback!.rank != null) {
        myRankLabel = '#${_myRankFallback!.rank}';
      } else if (_myRankFallback!.outsideTop100 &&
          _myRankFallback!.aura > 0) {
        myRankLabel = '100+';
      } else {
        myRankLabel = 'Unranked';
      }
      myBoardAura = _myRankFallback!.aura;
    } else {
      myRankLabel = 'Unranked';
      myBoardAura = 0;
    }

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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPill(
                            label: 'MONTHLY',
                            active: _isMonthly,
                            onTap: () {
                              if (_isMonthly) return;
                              setState(() {
                                _isMonthly = true;
                                _remoteLeaderboard = null;
                                _hasRemoteData = false;
                                _myRankFallback = null;
                              });
                              _fetchLeaderboard();
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildPill(
                            label: 'ALL TIME',
                            active: !_isMonthly,
                            onTap: () {
                              if (!_isMonthly) return;
                              setState(() {
                                _isMonthly = false;
                                _remoteLeaderboard = null;
                                _hasRemoteData = false;
                                _myRankFallback = null;
                              });
                              _fetchLeaderboard();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: !hasCollege
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Add your college in Edit Profile to view campus rankings.',
                                    ),
                                  ),
                                );
                              }
                            : () {
                                setState(() {
                                  _isCollege = !_isCollege;
                                  _remoteLeaderboard = null;
                                  _hasRemoteData = false;
                                  _myRankFallback = null;
                                });
                                _fetchLeaderboard();
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Ds.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Ds.border),
                          ),
                          child: Text(
                            isCollegeScopeActive ? 'COLLEGE' : 'GLOBAL',
                            style: DsText.caption.copyWith(
                              color: Ds.aura,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Season & Reset Window Banner (real info only)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: DsCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        _isMonthly
                            ? Icons.schedule_rounded
                            : Icons.public_rounded,
                        color: Ds.aura,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isMonthly
                                  ? _currentUtcMonthLabel()
                                  : 'ALL-TIME STANDINGS',
                              style: DsText.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isMonthly
                                  ? 'Resets 1st of month · 05:30 IST (00:00 UTC)'
                                  : (isCollegeScopeActive
                                      ? myCollege
                                      : 'Across all colleges on DevSpace'),
                              style: DsText.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if ((_isLoadingRemote && !_hasRemoteData) ||
                (usersP.isLoading && !hasData && _remoteError == null))
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Ds.aura),
                ),
              )
            else if (_remoteError != null && !hasData)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: Ds.muted),
                        const SizedBox(height: 12),
                        Text(
                          _remoteError!,
                          style: DsText.bodySm.copyWith(color: Ds.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 140,
                          child: DsButton(
                            label: 'Retry',
                            height: 44,
                            onPressed: _fetchLeaderboard,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        const Icon(Icons.emoji_events_outlined,
                            size: 64, color: Ds.muted),
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
                  child: _buildPodium(rankedUsers, ranks),
                ),
              ),

              // Ranks 4+
              if (rankedUsers.length > 3)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final userIndex = index + 3;
                        final u = rankedUsers[userIndex];
                        final isMe = me?.id == u.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildRankRow(
                            rank: ranks[userIndex],
                            user: u,
                            isMe: isMe,
                          ),
                        );
                      },
                      childCount: rankedUsers.length - 3,
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
      bottomSheet: me != null
          ? TourAnchor(
              id: TourAnchorId.myRankRow,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: Ds.navBg,
                  border: Border(
                    top: BorderSide(color: Ds.aura, width: 2),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Builder(
                    builder: (context) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(1.0);
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final isCompact = screenWidth < 420 ||
                          textScale > 1.15 ||
                          myRankLabel.length > 4;

                      if (isCompact) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  myRankLabel,
                                  style: (myRankLabel == 'Unranked'
                                          ? DsText.label
                                          : DsText.h3)
                                      .copyWith(
                                    color: myRankLabel == 'Unranked'
                                        ? Ds.muted
                                        : Ds.aura,
                                    fontSize: 14,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Ds.surface,
                                  child: Text(
                                    me.name.isNotEmpty
                                        ? me.name[0].toUpperCase()
                                        : 'U',
                                    style: DsText.caption
                                        .copyWith(color: Ds.bone),
                                  ),
                                ),
                                const DsTag('YOU', bg: Ds.aura, fg: Ds.ink),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        me.name,
                                        style: DsText.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '@${me.handle}',
                                        style: DsText.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$myBoardAura AURA',
                                  style: DsText.number.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Text(
                            myRankLabel,
                            style: (myRankLabel == 'Unranked'
                                    ? DsText.label
                                    : DsText.h3)
                                .copyWith(
                              color: myRankLabel == 'Unranked'
                                  ? Ds.muted
                                  : Ds.aura,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Ds.surface,
                            child: Text(
                              me.name.isNotEmpty
                                  ? me.name[0].toUpperCase()
                                  : 'U',
                              style: DsText.caption.copyWith(color: Ds.bone),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    Text(
                                      me.name,
                                      style: DsText.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const DsTag('YOU', bg: Ds.aura, fg: Ds.ink),
                                  ],
                                ),
                                Text(
                                  '@${me.handle}',
                                  style: DsText.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$myBoardAura AURA',
                            style: DsText.number.copyWith(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
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

  Widget _buildPodium(List<UserModel> users, List<int> ranks) {
    final first = users.isNotEmpty ? users[0] : null;
    final second = users.length > 1 ? users[1] : null;
    final third = users.length > 2 ? users[2] : null;
    final firstRank = ranks.isNotEmpty ? ranks[0] : 1;
    final secondRank = ranks.length > 1 ? ranks[1] : 2;
    final thirdRank = ranks.length > 2 ? ranks[2] : 3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Slot (Left)
        Expanded(
          child: _buildPodiumColumn(
            user: second,
            rank: secondRank,
            podiumHeight: 80,
            ringColor: secondRank == 1 ? Ds.aura : Ds.tierSilver,
            rankNumberStyle: DsText.h2.copyWith(
              color: secondRank == 1 ? Ds.aura : Ds.tierSilver,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 1st Slot (Center - Highest)
        Expanded(
          child: _buildPodiumColumn(
            user: first,
            rank: firstRank,
            podiumHeight: 110,
            ringColor: Ds.aura,
            rankNumberStyle: DsText.h1.copyWith(color: Ds.aura, fontSize: 36),
            isFirst: true,
          ),
        ),
        const SizedBox(width: 10),

        // 3rd Slot (Right)
        Expanded(
          child: _buildPodiumColumn(
            user: third,
            rank: thirdRank,
            podiumHeight: 60,
            ringColor: thirdRank == 1
                ? Ds.aura
                : (thirdRank == 2 ? Ds.tierSilver : Ds.tierBronze),
            rankNumberStyle: DsText.h3.copyWith(
              color: thirdRank == 1
                  ? Ds.aura
                  : (thirdRank == 2 ? Ds.tierSilver : Ds.tierBronze),
            ),
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
    final tierColor = RanksScreen.getTierColor(user.aura);
    final rankTag = RanksScreen.getRankTag(user.aura);

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
