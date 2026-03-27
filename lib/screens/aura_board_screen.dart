import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../models/badge_model.dart';
import '../theme/app_colors.dart';
import '../widgets/user_avatar.dart';
import '../widgets/aura_bar.dart';
import 'profile_screen.dart';

class AuraBoardScreen extends StatelessWidget {
  const AuraBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ranked  = context.watch<UsersProvider>().leaderboard;
    final medals  = ['🥇', '🥈', '🥉'];
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return ListView(
      padding: EdgeInsets.fromLTRB(0, topInset, 0, 100),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border))),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aura Leaderboard',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w900,
                    color: AppColors.text, letterSpacing: -0.5)),
              SizedBox(height: 3),
              Text('Top contributors this month · stay active to climb',
                  style: TextStyle(fontSize: 13, color: AppColors.text3)),
            ],
          ),
        ),

        // Ranked list
        ...ranked.asMap().entries.map((e) {
          final i    = e.key;
          final u    = e.value;
          final badge = getBadge(u.aura);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(userId: u.id)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: i == 0
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Center(
                      child: i < 3
                          ? Text(medals[i], style: const TextStyle(fontSize: 20))
                          : Text('#${i + 1}',
                              style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800,
                                color: AppColors.text3)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  UserAvatar(user: u, size: 46, showStory: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15,
                              color: AppColors.text)),
                        Text('@${u.handle} · ${u.academicLabel.isEmpty ? u.role : u.academicLabel}',
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.text3)),
                        const SizedBox(height: 6),
                        AuraBar(aura: u.aura),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(u.aura.toString(),
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w900,
                            color: badge.color)),
                      Text('${badge.icon} ${badge.name}',
                          style: const TextStyle(
                            fontSize: 11, color: AppColors.text3)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        // Badge tiers legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Badge Tiers',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.text3, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              ...kBadges.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: b.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text(b.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: b.color)),
                          Text(b.description,
                              style: const TextStyle(
                                fontSize: 12, color: AppColors.text3)),
                        ],
                      ),
                    ),
                    Text(
                      b.max == 999999999
                          ? '${b.min}+'
                          : '${b.min}–${b.max}',
                      style: const TextStyle(fontSize: 12, color: AppColors.text4),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}
