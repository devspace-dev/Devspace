import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import 'user_avatar.dart';

class StoryReel extends StatelessWidget {
  const StoryReel({super.key});

  @override
  Widget build(BuildContext context) {
    final me    = context.watch<AuthProvider>().currentUser;
    final users = context.watch<UsersProvider>().users;
    final all = [
      me,
      ...users.where((user) => user.id != me.id),
    ].take(7).toList();

    return Container(
      height: 90,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final u = all[i];
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                UserAvatar(user: u, size: 48, showStory: true),
                const SizedBox(height: 4),
                Flexible(
                  child: SizedBox(
                    width: 54,
                    child: Text(
                      i == 0 ? 'You' : u.name.split(' ').first,
                      style: const TextStyle(fontSize: 10, color: AppColors.text4),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
