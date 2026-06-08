import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/notifications_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsP = context.watch<NotificationsProvider>();
    final realNotifications = notificationsP.notifications;
    final authP = context.watch<AuthProvider>();
    final currentUser = authP.currentUserOrNull;

    // Define mock notifications matching Screen 7 if real notifications are empty
    final mockNotifications = [
      NotificationModel(
        id: 'mock_1',
        toUid: currentUser?.id ?? '',
        fromUid: 'user_arjun',
        type: 'like',
        message: 'Arjun liked your project',
        read: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        payload: {'senderName': 'Arjun', 'senderAvatar': 'A'},
      ),
      NotificationModel(
        id: 'mock_2',
        toUid: currentUser?.id ?? '',
        fromUid: 'user_priya',
        type: 'comment',
        message: 'Priya commented on your project',
        read: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        payload: {'senderName': 'Priya', 'senderAvatar': 'P'},
      ),
      NotificationModel(
        id: 'mock_3',
        toUid: currentUser?.id ?? '',
        fromUid: 'system',
        type: 'announcement',
        message: 'Google Summer of Code 2025 is closing in 3 days',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        payload: {'senderName': 'GSoC', 'senderAvatar': 'G'},
      ),
      NotificationModel(
        id: 'mock_4',
        toUid: currentUser?.id ?? '',
        fromUid: 'user_umang',
        type: 'follow',
        message: 'Umang started following you',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        payload: {'senderName': 'Umang', 'senderAvatar': 'U'},
      ),
      NotificationModel(
        id: 'mock_5',
        toUid: currentUser?.id ?? '',
        fromUid: 'user_hack',
        type: 'activity',
        message: 'Hack India 2025 registered you',
        read: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        payload: {'senderName': 'Hack India', 'senderAvatar': 'H'},
      ),
    ];

    final displayList = realNotifications.isNotEmpty ? realNotifications : mockNotifications;

    // Filter items for tabs
    final allNotifications = displayList;
    final mentions = displayList.where((n) => n.type == 'mention' || n.message.contains('@')).toList();
    final activity = displayList.where((n) => ['like', 'comment', 'follow', 'activity'].contains(n.type)).toList();

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textFor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ),
        actions: [
          if (realNotifications.isNotEmpty && currentUser != null)
            TextButton(
              onPressed: () => notificationsP.markAllAsRead(currentUser.id),
              child: Text(
                'Mark all as read',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Custom Sliding Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderFor(context).withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.textFor(context),
                unselectedLabelColor: AppColors.text3For(context),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Mentions'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _NotificationList(items: allNotifications),
                  _NotificationList(items: mentions),
                  _NotificationList(items: activity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<NotificationModel> items;
  const _NotificationList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.text3For(context)),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textFor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        color: AppColors.borderFor(context).withValues(alpha: 0.3),
        height: 24,
      ),
      itemBuilder: (context, index) {
        final n = items[index];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Determine icon based on notification type
        Widget typeIcon;
        Color iconColor = AppColors.primary;
        if (n.type == 'like') {
          typeIcon = const Icon(Icons.favorite_rounded, color: AppColors.like, size: 16);
        } else if (n.type == 'comment') {
          typeIcon = const Icon(Icons.chat_bubble_rounded, color: Colors.orange, size: 14);
        } else if (n.type == 'follow') {
          typeIcon = const Icon(Icons.person_add_rounded, color: Colors.blue, size: 14);
        } else {
          typeIcon = const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 15);
        }

        // Generate a beautiful profile icon placeholder
        String initial = n.payload?['senderName']?.isNotEmpty == true
            ? n.payload!['senderName'][0].toUpperCase()
            : (n.message.isNotEmpty ? n.message[0].toUpperCase() : 'D');

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: typeIcon,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                            color: AppColors.textFor(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time indicator
                      Text(
                        _formatTimeAgo(n.createdAt),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text3For(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (!n.read)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
