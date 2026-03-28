import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/users_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/profile_card.dart';
import 'profile_screen.dart';

enum ConnectionListType { followers, following }

class ConnectionsScreen extends StatefulWidget {
  final UserModel user;
  final ConnectionListType type;

  const ConnectionsScreen({
    super.key,
    required this.user,
    required this.type,
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late Future<List<UserModel>> _connectionsFuture;
  String _query = '';

  bool get _showFollowers => widget.type == ConnectionListType.followers;
  String get _title => _showFollowers ? 'Followers' : 'Following';
  String get _subtitle => _showFollowers
      ? 'Builders paying attention to ${widget.user.handle}'
      : 'People ${widget.user.handle} is learning from and keeping up with';

  @override
  void initState() {
    super.initState();
    _connectionsFuture = _loadConnections();
  }

  Future<List<UserModel>> _loadConnections() {
    final usersProvider = context.read<UsersProvider>();
    return _showFollowers
        ? usersProvider.followersFor(widget.user.id)
        : usersProvider.followingFor(widget.user.id);
  }

  void _refresh() {
    setState(() {
      _connectionsFuture = _loadConnections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(context),
        title: Text(_title),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _connectionsFuture,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final users = snapshot.data ?? const <UserModel>[];
          final filteredUsers = users.where((user) {
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return user.name.toLowerCase().contains(q) ||
                user.handle.toLowerCase().contains(q) ||
                user.branch.toLowerCase().contains(q) ||
                user.stack.any((item) => item.toLowerCase().contains(q));
          }).toList();

          if (waiting) {
            return const AppLoadingState(
              title: 'Loading network',
              message: 'Pulling your builder graph from DevSpace.',
            );
          }

          if (snapshot.hasError) {
            return AppErrorState(
              title: 'Unable to load list',
              message: '${snapshot.error}',
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _ConnectionsHero(
                    title: _title,
                    subtitle: _subtitle,
                    count: users.length,
                    accent: _showFollowers ? AppColors.primary : AppColors.mint,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    style: TextStyle(color: AppColors.textFor(context)),
                    decoration: InputDecoration(
                      hintText: 'Search by name, handle, branch, or stack',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),
              ),
              if (filteredUsers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmptyState(
                    icon: _showFollowers
                        ? Icons.people_outline_rounded
                        : Icons.person_search_rounded,
                    title: _query.isEmpty ? 'No $_title yet' : 'No matches',
                    message: _query.isEmpty
                        ? _showFollowers
                            ? 'Nobody is following this profile yet.'
                            : 'This profile is not following anyone yet.'
                        : 'Try a different keyword.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final user = filteredUsers[index];
                      return ProfileCard(
                        user: user,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: user.id),
                          ),
                        ),
                      ).animate().fadeIn(
                            delay: (index * 35).ms,
                            duration: 320.ms,
                          ).slideY(begin: 0.08, end: 0);
                    },
                    childCount: filteredUsers.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionsHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final Color accent;

  const _ConnectionsHero({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.2),
            AppColors.bg2For(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: accent.withValues(alpha: 0.25),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -10,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textFor(context),
                  letterSpacing: -1,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.text2For(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}
