import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/users_provider.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/user_avatar.dart';
import 'chat_detail_screen.dart';
import 'people_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Consumer<MessagesProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildSearchBar(context),
                  ),
                ),
                if (provider.isLoading && provider.conversations.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                else if (provider.error != null &&
                    provider.conversations.isEmpty)
                  SliverFillRemaining(
                    child: _buildErrorState(context, provider, me.id),
                  )
                else if (provider.conversations.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = provider.conversations[index];
                          final otherId = conv.participants.firstWhere(
                              (id) => id != me.id,
                              orElse: () => '');

                          if (otherId.isEmpty) return const SizedBox.shrink();

                          return FutureBuilder<UserModel?>(
                            future:
                                context.read<UsersProvider>().getUser(otherId),
                            builder: (context, snap) {
                              final other = snap.data;
                              if (other == null) return const SizedBox.shrink();

                              if (_searchQuery.isNotEmpty) {
                                if (!other.name
                                        .toLowerCase()
                                        .contains(_searchQuery) &&
                                    !(conv.lastMessage
                                            ?.toLowerCase()
                                            .contains(_searchQuery) ??
                                        false)) {
                                  return const SizedBox.shrink();
                                }
                              }

                              return _ConversationCard(
                                conversation: conv,
                                otherUser: other,
                                meId: me.id,
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: (index * 50).ms,
                                    duration: 400.ms,
                                  )
                                  .slideX(begin: 0.05, end: 0);
                            },
                          );
                        },
                        childCount: provider.conversations.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PeopleScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          'New Chat',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      )
          .animate()
          .scale(delay: 400.ms, duration: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: AppColors.bgFor(context),
      expandedHeight: 80,
      centerTitle: false,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textFor(context)),
          onPressed: () => _showTopOptions(context),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        title: Text(
          'Messages',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: AppColors.textFor(context),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          onChanged: (value) =>
              setState(() => _searchQuery = value.toLowerCase()),
          style: TextStyle(color: AppColors.textFor(context)),
          decoration: InputDecoration(
            hintText: 'Search people or messages...',
            hintStyle: TextStyle(
              color: AppColors.text3For(context),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.text3For(context),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

  void _showTopOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2For(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              context,
              icon: Icons.done_all_rounded,
              label: 'Mark all as read',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                // Implementation for mark all as read
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.archive_outlined,
              label: 'Archived chats',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.settings_outlined,
              label: 'Message Settings',
              color: Colors.blueGrey,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.textFor(context),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildErrorState(
      BuildContext context, MessagesProvider provider, String meId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: AppColors.text3For(context)),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.text2For(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.init(meId, force: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined,
              size: 64, color: AppColors.text3For(context).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with other founders to start chatting.',
            style: TextStyle(color: AppColors.text3For(context)),
          ),
        ],
      ),
    );
  }

  void _showConversationOptions(
      BuildContext context, dynamic conv, UserModel other) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border2For(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(
              context,
              icon: Icons.done_all_rounded,
              label: 'Mark as Read',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                final me = context.read<AuthProvider>().currentUser;
                context
                    .read<MessagesProvider>()
                    .markConversationRead(conv.id, me.id);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.notifications_off_rounded,
              label: 'Mute Notifications',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildOptionTile(
              context,
              icon: Icons.delete_rounded,
              label: 'Delete Conversation',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final dynamic conversation;
  final UserModel otherUser;
  final String meId;

  const _ConversationCard({
    required this.conversation,
    required this.otherUser,
    required this.meId,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                conversation: conversation,
                otherUser: otherUser,
              ),
            ),
          );
        },
        onLongPress: () {
          // Accessing the state to show options
          final state = context.findAncestorStateOfType<_MessagesScreenState>();
          state?._showConversationOptions(context, conversation, otherUser);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              UserAvatar(
                user: otherUser,
                size: 60,
                showRing: hasUnread,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight:
                                  hasUnread ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.textFor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (conversation.lastMessageAt != null)
                          Text(
                            _formatTime(conversation.lastMessageAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.text3For(context),
                              fontWeight:
                                  hasUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'Start a conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: hasUnread
                                  ? AppColors.textFor(context)
                                  : AppColors.text3For(context),
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) {
      return DateFormat('HH:mm').format(dt);
    } else if (today.difference(date).inDays == 1) {
      return 'Yesterday';
    } else if (today.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(dt);
    } else {
      return DateFormat('dd/MM/yy').format(dt);
    }
  }
}
