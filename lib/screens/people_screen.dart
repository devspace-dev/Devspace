import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/profile_card.dart';
import 'profile_screen.dart';

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersP = context.watch<UsersProvider>();
    final users = usersP.users;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: topInset + 20),
        ),
        
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -1.0,
                  ),
                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                const SizedBox(height: 4),
                Text(
                  'Connect with other developers building on campus.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.text3,
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        if (usersP.isLoading && users.isEmpty)
          const SliverFillRemaining(
            child: AppLoadingState(
              title: 'Finding Devs',
              message: 'Connecting with the campus network...',
            ),
          )
        else if (users.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Empty Campus',
              message: 'Be the first to join the developer community!',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => ProfileCard(
                user: users[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: users[i].id)),
                ),
              ),
              childCount: users.length,
            ),
          ),
          
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
