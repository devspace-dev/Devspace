import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/devspace_ui_helper.dart';
import 'user_avatar.dart';

class CollegeLeaderboard extends StatelessWidget {
  const CollegeLeaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usersP = context.watch<UsersProvider>();
    final me = auth.currentUserOrNull;
    
    if (me == null) return const SizedBox.shrink();

    // Filter and sort users by college and aura
    final collegeUsers = usersP.users
        .where((u) => u.college == me.college)
        .toList();
    
    collegeUsers.sort((a, b) => b.aura.compareTo(a.aura));
    
    final top5 = collegeUsers.take(5).toList();
    
    // Find my rank
    final myRankIndex = collegeUsers.indexWhere((u) => u.id == me.id);
    final myRank = myRankIndex + 1;
    final isMeInTop5 = myRankIndex >= 0 && myRankIndex < 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DevSpaceColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏆 Top Devs at ${me.college}',
            style: DevSpaceColors.headingStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(height: 20),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top5.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = top5[index];
              return _LeaderboardRow(
                user: user,
                rank: index + 1,
                isCurrentUser: user.id == me.id,
              );
            },
          ),
          
          if (!isMeInTop5 && myRankIndex != -1) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10),
            ),
            _LeaderboardRow(
              user: me,
              rank: myRank,
              isCurrentUser: true,
              highlight: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final dynamic user; // UserModel
  final int rank;
  final bool isCurrentUser;
  final bool highlight;

  const _LeaderboardRow({
    required this.user,
    required this.rank,
    this.isCurrentUser = false,
    this.highlight = false,
  });

  Color _getRankColor() {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return DevSpaceColors.gray;
  }

  @override
  Widget build(BuildContext context) {
    final tier = TierHelper.getTier(user.aura);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? DevSpaceColors.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: highlight 
            ? const Border(left: BorderSide(color: DevSpaceColors.primary, width: 4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: DevSpaceColors.headingStyle(
                fontSize: 16,
                color: _getRankColor(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          UserAvatar(user: user, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? 'You' : user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tier.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier.name.toUpperCase(),
                    style: TextStyle(
                      color: tier.accentColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            user.aura.toString(),
            style: DevSpaceColors.headingStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
