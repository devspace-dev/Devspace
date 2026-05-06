import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/badge_model.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
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
  String _timeframe = 'All Time'; // 'Weekly', 'Monthly' or 'All Time'
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUserOrNull;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      extendBodyBehindAppBar: true,
      appBar: canPop ? AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ) : null,
      body: AppGradientBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            physics: const BouncingScrollPhysics(),
            children: [
              // Header
              _buildHeader(context, canPop),
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
                        'No aura activity found for this timeframe yet.',
                        style: TextStyle(
                          color: AppColors.text3For(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      _buildPodium(context, top3),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: remaining.map((u) {
                            final index = ranked.indexOf(u);
                            final isMe = u.id == currentUser?.id;
                            return _buildRankItem(context, u, index, isMe);
                          }).toList(),
                        ),
                      ),
                      _buildTiersLegend(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPushed) {
    final currentUser = context.watch<AuthProvider>().currentUserOrNull;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isPushed ? 10 : 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_isGlobal ? 'Global Leaderboard' : '${currentUser?.college ?? "My College"} Rank',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textFor(context),
                      letterSpacing: -0.5,
                    )),
              ),
              _buildScopeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeframeToggle(),
        ],
      ),
    );
  }

  Widget _buildScopeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScopeIcon(
            icon: Icons.public,
            isSelected: _isGlobal,
            onTap: () => setState(() {
              _isGlobal = true;
              _rankingFuture = _loadRankedUsers();
            }),
          ),
          _ScopeIcon(
            icon: Icons.school,
            isSelected: !_isGlobal,
            onTap: () => setState(() {
              _isGlobal = false;
              _rankingFuture = _loadRankedUsers();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Weekly', 'Monthly', 'All Time'].map((t) {
          final isSelected = _timeframe == t;
          return GestureDetector(
            onTap: () => setState(() {
              _timeframe = t;
              _rankingFuture = _loadRankedUsers();
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Text(
                t,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text3For(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<List<UserModel>> _loadRankedUsers() async {
    final usersProvider = context.read<UsersProvider>();
    final currentUser = context.read<AuthProvider>().currentUserOrNull;
    
    if (_timeframe == 'All Time') {
      final source = _isGlobal
          ? usersProvider.users
          : usersProvider.collegeLeaderboard(currentUser?.college ?? '');
      
      final ranked = List<UserModel>.from(source)
        ..sort((a, b) => b.aura.compareTo(a.aura));
      return ranked;
    }

    final cutoff = _timeframe == 'Weekly'
        ? DateTime.now().subtract(const Duration(days: 7))
        : DateTime.now().subtract(const Duration(days: 30));

    final totals = await SupabaseService.instance.getAuraTotalsSince(cutoff);
    final source = _isGlobal
        ? usersProvider.users
        : usersProvider.collegeLeaderboard(currentUser?.college ?? '');

    final ranked = source
        .map((user) => user.copyWith(aura: totals[user.id] ?? 0))
        .toList()
      ..sort((a, b) => b.aura.compareTo(a.aura));

    return ranked;
  }

  Widget _buildPodium(BuildContext context, List<UserModel> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();
    
    // Order for visual podium: [2, 1, 3]
    final podiumOrder = <int>[];
    if (top3.length > 1) podiumOrder.add(1);
    podiumOrder.add(0);
    if (top3.length > 2) podiumOrder.add(2);

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
                MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      UserAvatar(user: user, size: isFirst ? 86 : 70, showStory: false),
                      if (isFirst)
                        const Positioned(
                          top: -24,
                          child: Text('👑', style: TextStyle(fontSize: 28)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name.split(' ')[0],
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
                      color: getBadge(user.aura).color,
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

  Widget _buildRankItem(BuildContext context, UserModel u, int index, bool isMe) {
    final badge = getBadge(u.aura);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bg2For(context),
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
                    color: isMe ? AppColors.primary : AppColors.text3For(context),
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
                          child: Text(u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.textFor(context))),
                        ),
                        if (u.roles.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    Text('@${u.handle}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text3For(context))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(u.aura.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: badge.color)),
                  Text(badge.name,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3For(context),
                        letterSpacing: 0.3,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index % 10 * 50).ms).slideX(begin: 0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildTiersLegend(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('AURA TIERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.text3For(context),
                letterSpacing: 1.5,
              )),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: kBadges.map((b) => _TierCard(badge: b)).toList(),
          ),
        ],
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
    final color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[400] : Colors.brown[300]);

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

class _TierCard extends StatelessWidget {
  final BadgeModel badge;

  const _TierCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badge.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(badge.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(badge.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: badge.color,
                    )),
                Text(
                  badge.max == 999999999 ? '${badge.min}+' : '${badge.min}–${badge.max}',
                  style: TextStyle(fontSize: 11, color: AppColors.text3For(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScopeIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.text3For(context),
        ),
      ),
    );
  }
}


