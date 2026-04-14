import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/profile_card.dart';
import 'profile_screen.dart';

class PeopleScreen extends StatefulWidget {
  final String initialQuery;

  const PeopleScreen({
    super.key,
    this.initialQuery = '',
  });
  const PeopleScreen.withQuery({
    super.key,
    required this.initialQuery,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController.text = widget.initialQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersP = context.watch<UsersProvider>();
    final users = usersP.search(_query);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: RefreshIndicator.adaptive(
        color: AppColors.primary,
        onRefresh: usersP.refreshUsers,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: _DevelopersHero(
                  totalDevelopers: usersP.users.length,
                  activeQuery: _query,
                  searchController: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
            if (usersP.isLoading && usersP.users.isEmpty)
              const SliverFillRemaining(
                child: AppLoadingState(
                  title: 'Searching',
                  message: 'Finding developers on campus...',
                ),
              )
            else if (usersP.error != null && users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorState(
                  title: 'Developers unavailable',
                  message: usersP.error!,
                  actionLabel: 'Retry',
                  onAction: usersP.refreshUsers,
                ),
              )
            else if (usersP.error != null && users.isNotEmpty)
              SliverToBoxAdapter(
                child: _InlineWarningBanner(
                  message: usersP.error!,
                  onRetry: usersP.refreshUsers,
                ),
              )
            else if (users.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: _query.isEmpty ? 'No Developers' : 'No matches',
                  message: _query.isEmpty
                      ? 'Be the first to join the community.'
                      : 'Try a different skill, branch, or name.',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final user = users[i];
                    return ProfileCard(
                      user: user,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(userId: user.id),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: (i * 30).ms,
                          duration: 300.ms,
                        )
                        .slideX(begin: 0.03, end: 0);
                  },
                  childCount: users.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _DevelopersHero extends StatelessWidget {
  final int totalDevelopers;
  final String activeQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _DevelopersHero({
    required this.totalDevelopers,
    required this.activeQuery,
    required this.searchController,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.indigo.withValues(alpha: 0.1),
            AppColors.bg2For(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -14,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 16,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgFor(context).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      '$totalDevelopers builders',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textFor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Find your next dev circle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -1,
                  color: AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search students by stack, branch, project, or handle and discover who is actually building on campus.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.text2For(context),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                onChanged: onChanged,
                style: TextStyle(color: AppColors.textFor(context)),
                decoration: InputDecoration(
                  hintText: 'Search Flutter, AI, @handle, CSE...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: activeQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: onClear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
  }
}

class _InlineWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineWarningBanner({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.text2For(context),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
