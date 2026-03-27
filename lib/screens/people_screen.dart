import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
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
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: topInset),
        ),
        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Developers',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),

        if (usersP.isLoading && users.isEmpty)
          const SliverFillRemaining(
            child: AppLoadingState(
              title: 'Searching',
              message: 'Finding developers on campus...',
            ),
          )
        else if (users.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No Developers',
              message: 'Be the first to join the community.',
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
