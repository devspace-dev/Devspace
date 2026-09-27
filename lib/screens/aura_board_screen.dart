import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../services/monthly_aura_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import '../widgets/user_avatar.dart';
import 'profile_screen.dart';

class AuraBoardScreen extends StatefulWidget {
  const AuraBoardScreen({super.key});

  @override
  State<AuraBoardScreen> createState() => _AuraBoardScreenState();
}

class _AuraBoardScreenState extends State<AuraBoardScreen> {
  // Two leaderboard boards:
  // 1. 'Monthly' (starts from 0 every month and resets at the end of the month)
  // 2. 'All Time' (stores total points earned across all time)
  String _boardType = 'Monthly';

  // Two scope sections in both leaderboards:
  // true -> 'Global', false -> 'College'
  bool _isGlobal = true;

  Future<List<UserModel>>? _rankingFuture;
  int _lastUsersCount = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final usersCount = context.watch<UsersProvider>().users.length;
    if (_rankingFuture == null || usersCount != _lastUsersCount) {
      _lastUsersCount = usersCount;
      _rankingFuture = _loadRankedUsers();
    }
  }

  Future<List<UserModel>> _loadRankedUsers() async {
    final currentUser = context.read<AuthProvider>().currentUserOrNull;
    final collegeFilter = _isGlobal ? null : currentUser?.college;

    try {
      if (_boardType == 'Monthly') {
        return await SupabaseService.instance
            .getMonthlyAuraLeaderboard(college: collegeFilter);
      } else {
        return await SupabaseService.instance
            .getAllTimeAuraLeaderboard(college: collegeFilter);
      }
    } catch (e) {
      debugPrint('Leaderboard fetch failed: $e');
      return currentUser != null ? [currentUser.copyWith(aura: 0)] : [];
    }
  }

  void _refreshLeaderboard() {
    setState(() {
      _rankingFuture = _loadRankedUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUserOrNull;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      extendBodyBehindAppBar: true,
      appBar: canPop
          ? AppBar(
              leading: const BackButton(),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: AppGradientBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator.adaptive(
            color: AppColors.primary,
            onRefresh: () async {
              _refreshLeaderboard();
              await _rankingFuture;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildHeader(context, canPop),
                _buildBoardInfoBanner(context),
                FutureBuilder<List<UserModel>>(
                  future: _rankingFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      );
                    }

                    final ranked = snapshot.data ?? const <UserModel>[];
                    final top3 = ranked.take(3).toList();
                    final remaining = ranked.skip(3).toList();

                    if (ranked.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _isGlobal
                              ? 'No builders found yet.'
                              : 'No builders found for your college yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text3For(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Top 3 Podium displayed in both Monthly and All Time leaderboards
                        // and across both Global and College sections
                        _buildPodium(context, top3),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: remaining.asMap().entries.map((entry) {
                              final rankIndex = entry.key + 3; // 0-based index (rank 4 is index 3)
                              final u = entry.value;
                              final isMe = u.id == currentUser?.id;
                              return _buildRankItem(context, u, rankIndex, isMe);
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPushed) {
    final currentUser = context.watch<AuthProvider>().currentUserOrNull;
    final collegeName = (currentUser?.college.trim().isNotEmpty ?? false)
        ? currentUser!.college
        : 'My College';

    return Padding(
      padding: EdgeInsets.fromLTRB(20, isPushed ? 10 : 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isGlobal ? 'Global Leaderboard' : '$collegeName Leaderboard',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          // 1. Board Selector: Monthly vs All Time
          _buildBoardTypeToggle(context),
          const SizedBox(height: 10),
          // 2. Scope Selector: Global vs College (present in both Monthly & All Time)
          _buildScopeSectionToggle(context, collegeName),
        ],
      ),
    );
  }

  Widget _buildBoardTypeToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ['Monthly', 'All Time'].map((board) {
          final isSelected = _boardType == board;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_boardType == board) return;
                setState(() {
                  _boardType = board;
                  _rankingFuture = _loadRankedUsers();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      board == 'Monthly'
                          ? Icons.calendar_month_rounded
                          : Icons.emoji_events_rounded,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : AppColors.text3For(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      board == 'Monthly'
                          ? 'Monthly Board'
                          : 'All Time Board',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? Colors.white
                            : AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScopeSectionToggle(BuildContext context, String collegeName) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isGlobal) return;
                setState(() {
                  _isGlobal = true;
                  _rankingFuture = _loadRankedUsers();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _isGlobal
                      ? AppColors.bg2For(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _isGlobal
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 15,
                      color: _isGlobal
                          ? AppColors.primary
                          : AppColors.text3For(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Global',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isGlobal
                            ? AppColors.textFor(context)
                            : AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isGlobal) return;
                setState(() {
                  _isGlobal = false;
                  _rankingFuture = _loadRankedUsers();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: !_isGlobal
                      ? AppColors.bg2For(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: !_isGlobal
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 15,
                      color: !_isGlobal
                          ? AppColors.primary
                          : AppColors.text3For(context),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'College',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: !_isGlobal
                              ? AppColors.textFor(context)
                              : AppColors.text3For(context),
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

  Widget _buildBoardInfoBanner(BuildContext context) {
    final seasonName = MonthlyAuraService.instance.currentSeasonName;
    final daysLeft = MonthlyAuraService.instance.daysRemainingInMonth;
    final isMonthly = _boardType == 'Monthly';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            const Color(0xFF7C3AED).withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMonthly
                      ? Icons.event_repeat_rounded
                      : Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isMonthly
                                ? seasonName
                                : 'All-Time Hall of Builders',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textFor(context),
                            ),
                          ),
                        ),
                        if (isMonthly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$daysLeft days left',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber[800],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMonthly
                          ? 'Starts at 0 every month & resets at month end. Only stores Aura earned this month!'
                          : 'Cumulative Aura points earned across all time.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text3For(context),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _ScoringRulePill(
                label: 'Practice Q&A: +5 / +10 / +15 / +20',
              ),
              _ScoringRulePill(
                label: 'Daily Mission: +20 Solved • +5 Attempt',
              ),
              _ScoringRulePill(
                label: 'Arena Combat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<UserModel> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final podiumOrder = <int>[];
    if (top3.length > 1) podiumOrder.add(1); // 2nd Place (Left)
    podiumOrder.add(0); // 1st Place (Center)
    if (top3.length > 2) podiumOrder.add(2); // 3rd Place (Right)

    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: podiumOrder.map((index) {
          final user = top3[index];
          final rank = index + 1;
          final isFirst = rank == 1;

          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: user.id)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(
                          user: user, size: isFirst ? 86 : 70, showStory: false),
                      if (isFirst)
                        const Positioned(
                          top: -24,
                          child: Text('👑', style: TextStyle(fontSize: 28)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name.split(' ').first,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textFor(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.aura}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PodiumBase(rank: rank, isFirst: isFirst),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn().moveY(begin: 30, curve: Curves.easeOutBack);
  }

  Widget _buildRankItem(
      BuildContext context, UserModel u, int index, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderFor(context).withValues(alpha: 0.4),
            width: isMe ? 1.2 : 0.5,
          ),
        ),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color:
                        isMe ? AppColors.primary : AppColors.text3For(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              UserAvatar(user: u, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textFor(context),
                            ),
                          ),
                        ),
                        if (u.roles.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              u.roles.first.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      '@${u.handle}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text3For(context),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    u.aura.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index % 10 * 50).ms).slideX(
        begin: 0.1, curve: Curves.easeOutQuad);
  }
}

class _ScoringRulePill extends StatelessWidget {
  final String label;

  const _ScoringRulePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.text2For(context),
        ),
      ),
    );
  }
}

class _PodiumBase extends StatelessWidget {
  final int rank;
  final bool isFirst;

  const _PodiumBase({required this.rank, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final height = isFirst ? 80.0 : 60.0;
    final color = rank == 1
        ? Colors.amber
        : (rank == 2 ? Colors.grey[400] : Colors.brown[300]);

    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color!.withValues(alpha: 0.8),
            color.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -5,
          )
        ],
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
