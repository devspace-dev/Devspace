import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../data/badges_data.dart';
import '../services/supabase_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/posts_provider.dart';
import '../providers/users_provider.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/connections_screen.dart';
import '../screens/founder_tools_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/aura_history_screen.dart';
import '../screens/settings_screen.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/post_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/github_stats_card.dart';
import '../widgets/app_ui_kit.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _fetchedUser;
  bool _loading = false;
  String? _fetchError;
  Set<String> _earnedBadgeKeys = {};
  Map<String, DateTime?> _badgeAwardedDates = {};


  @override
  void initState() {
    super.initState();
    _fetchUserIfNeeded();
    _loadBadges();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _fetchedUser = null;
      _fetchUserIfNeeded();
      _loadBadges();
    }
  }

  Future<void> _fetchUserIfNeeded() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final isMe = widget.userId == null || widget.userId == me?.id;
    if (isMe) return;

    final usersP = context.read<UsersProvider>();
    final cached = usersP.getUserById(widget.userId!);
    if (cached != null) return;

    setState(() {
      _loading = true;
      _fetchError = null;
    });

    try {
      final user = await usersP.getUser(widget.userId!);
      if (mounted) {
        setState(() {
          _fetchedUser = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadBadges() async {
    final me = context.read<AuthProvider>().currentUserOrNull;
    final targetId = widget.userId ?? me?.id;
    if (targetId == null) return;

    final isMe = widget.userId == null || widget.userId == me?.id;
    if (isMe) {
      try {
        await SupabaseService.instance.syncMyBadges(userId: targetId);
      } catch (_) {}
    }

    try {
      final rows = await SupabaseService.instance.getUserBadges(targetId);
      if (mounted) {
        setState(() {
          _earnedBadgeKeys = rows.map((r) => r['badge_key'].toString()).toSet();
          _badgeAwardedDates = {
            for (final r in rows)
              r['badge_key'].toString(): r['awarded_at'] == null
                  ? null
                  : DateTime.tryParse(r['awarded_at'].toString()),
          };
        });
      }
    } catch (_) {}
  }

  void _showBadgeDetailSheet(
    BuildContext context,
    CommunityBadgeDefinition badgeDef,
    bool isEarned,
    DateTime? awardedAt,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        decoration: BoxDecoration(
          color: AppColors.bg2For(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.borderFor(ctx)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderFor(ctx),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isEarned
                        ? badgeDef.accentColor.withValues(alpha: 0.15)
                        : AppColors.bg3For(ctx),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isEarned
                          ? badgeDef.accentColor.withValues(alpha: 0.4)
                          : AppColors.borderFor(ctx),
                    ),
                  ),
                  child: Text(
                    badgeDef.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              badgeDef.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textFor(ctx),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isEarned
                                  ? const Color(0xFF81C784).withValues(alpha: 0.15)
                                  : AppColors.borderFor(ctx).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isEarned ? 'EARNED' : 'LOCKED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isEarned
                                    ? const Color(0xFF81C784)
                                    : AppColors.text3For(ctx),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badgeDef.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.text2For(ctx),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bg3For(ctx),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderFor(ctx)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REQUIREMENT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text3For(ctx),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badgeDef.rule,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textFor(ctx),
                    ),
                  ),
                  if (isEarned && awardedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Earned ${timeago.format(awardedAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: badgeDef.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Badges celebrate student milestones (carry 0 Aura).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.text3For(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, UserModel profileUser) {
    final earnedCount = _earnedBadgeKeys.length;
    final totalCount = kCommunityBadges.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderFor(context).withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: Color(0xFFFFD54F),
              ),
              const SizedBox(width: 8),
              Text(
                'BADGES & ACHIEVEMENTS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text3For(context),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$earnedCount / $totalCount UNLOCKED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFD54F),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kCommunityBadges.map((badgeDef) {
                  final isEarned = _earnedBadgeKeys.contains(badgeDef.key);
                  final awardedAt = _badgeAwardedDates[badgeDef.key];

                  return GestureDetector(
                    onTap: () => _showBadgeDetailSheet(context, badgeDef, isEarned, awardedAt),
                    child: Container(
                      width: itemWidth,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? badgeDef.accentColor.withValues(alpha: 0.08)
                            : AppColors.bg3For(context).withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEarned
                              ? badgeDef.accentColor.withValues(alpha: 0.45)
                              : AppColors.borderFor(context).withValues(alpha: 0.35),
                          width: isEarned ? 1.4 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                badgeDef.icon,
                                style: const TextStyle(fontSize: 22),
                              ),
                              const Spacer(),
                              if (isEarned)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: Color(0xFF81C784),
                                )
                              else
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: AppColors.text3For(context).withValues(alpha: 0.6),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badgeDef.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isEarned
                                  ? AppColors.textFor(context)
                                  : AppColors.text3For(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEarned
                                ? (awardedAt != null
                                    ? 'Earned ${timeago.format(awardedAt, locale: 'en_short')}'
                                    : 'Earned')
                                : badgeDef.rule,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: isEarned
                                  ? badgeDef.accentColor
                                  : AppColors.text3For(context).withValues(alpha: 0.8),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openProfileEditor(BuildContext context) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(
          mode: ProfileSetupMode.edit,
        ),
      ),
    );
  }

  Future<void> _showProfilePicture(BuildContext context, UserModel user) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.bg2For(dialogContext),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.borderFor(dialogContext)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: user.isImageAvatar
                          ? CachedNetworkImage(
                              imageUrl: StorageService.instance.resolvePublicUrl(user.avatar),
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _AvatarPreviewFallback(user: user),
                            )
                          : _AvatarPreviewFallback(user: user),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      user.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textFor(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.handle}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3For(dialogContext),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      width: 120,
                      height: 44,
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showAvatarActions(
    BuildContext context, {
    required UserModel user,
    required bool isMe,
  }) async {
    HapticFeedback.selectionClick();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bg2For(sheetContext),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderFor(sheetContext)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border2For(sheetContext),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  UserAvatar(user: user, size: 68, showRing: true, showStory: true),
                  const SizedBox(height: 10),
                  Text(
                    'Profile picture',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textFor(sheetContext),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isMe
                        ? 'View it, update it, or jump into profile editing.'
                        : 'View this profile picture.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text3For(sheetContext),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _AvatarActionTile(
                    icon: Icons.visibility_outlined,
                    title: 'View profile picture',
                    subtitle: 'Open the profile picture in a larger view.',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _showProfilePicture(context, user);
                    },
                  ),
                  if (isMe)
                    _AvatarActionTile(
                      icon: Icons.photo_camera_back_outlined,
                      title: user.isImageAvatar
                          ? 'Change profile picture'
                          : 'Add profile picture',
                      subtitle: 'Open profile editing to update your avatar.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _openProfileEditor(context);
                      },
                    ),
                  if (isMe)
                    _AvatarActionTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit profile',
                      subtitle: 'Update your profile details and public info.',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _openProfileEditor(context);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    if (me == null) {
      return Scaffold(backgroundColor: AppColors.bgFor(context));
    }

    final usersP = context.watch<UsersProvider>();
    final postsP = context.watch<PostsProvider>();
    final isMe = widget.userId == null || widget.userId == me.id;
    final user = isMe ? me : (usersP.getUserById(widget.userId!) ?? _fetchedUser);

    if (!isMe && user == null && (usersP.isLoading || _loading)) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        body: const SafeArea(child: ProfileSkeleton()),
      );
    }

    if (!isMe && user == null && (usersP.error != null || _fetchError != null)) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(backgroundColor: AppColors.bgFor(context)),
        body: AppErrorState(
          title: 'Profile unavailable',
          message: usersP.error ?? _fetchError!,
          actionLabel: 'Retry',
          onAction: () {
            usersP.refreshUsers();
            _fetchUserIfNeeded();
          },
        ),
      );
    }

    if (!isMe && user == null) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(backgroundColor: AppColors.bgFor(context)),
        body: AppEmptyState(
          icon: Icons.person_search_rounded,
          title: 'Profile unavailable',
          message: 'We could not find this student profile.',
          actionLabel: 'Refresh',
          onAction: () {
            usersP.refreshUsers();
            _fetchUserIfNeeded();
          },
        ),
      );
    }

    final profileUser = user!;
    final posts = postsP.postsForUser(profileUser.id);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bgFor(context).withValues(alpha: 0.92),
            surfaceTintColor: Colors.transparent,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textFor(context),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              profileUser.handle,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.textFor(context),
              ),
            ),
            actions: [
              if (isMe)
                Row(
                  children: [
                    if (profileUser.isAdmin || profileUser.isFounder)
                      _HeaderAction(
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FounderToolsScreen(
                                mode: FounderToolsMode.founderTools,
                              ),
                            ),
                          );
                        },
                      ),
                    _HeaderAction(
                      icon: Icons.settings_outlined,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              else
                Row(
                  children: [
                    _HeaderAction(
                      icon: Icons.mail_outline_rounded,
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        final provider = context.read<MessagesProvider>();
                        try {
                          final conv = await provider.startConversation(
                            me.id,
                            profileUser.id,
                          );
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                conversation: conv,
                                otherUser: profileUser,
                              ),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString()),
                                behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Avatar
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () => _showAvatarActions(
                            context,
                            user: profileUser,
                            isMe: isMe,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: UserAvatar(
                              user: profileUser,
                              size: 110,
                              showRing: false,
                              showStory: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Name and Verified Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          profileUser.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textFor(context),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (profileUser.isFounder) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppColors.primary, size: 22),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Handle
                  Center(
                    child: Text(
                      '@${profileUser.handle}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text3For(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title / Role (Founder @ DevSpace or Builder)
                  Center(
                    child: Text(
                      profileUser.roles.isNotEmpty ? profileUser.roles.first : 'Builder @ DevSpace',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text2For(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bio
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        profileUser.bio.isEmpty
                            ? 'Building tools and communities for student developers.'
                            : profileUser.bio,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.text3For(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row: Aura, Followers, Following
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(context, '${profileUser.aura}', 'Aura', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuraHistoryScreen()),
                        );
                      }),
                      _buildStatColumn(context, '${profileUser.followers}', 'Followers', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConnectionsScreen(
                              user: profileUser,
                              type: ConnectionListType.followers,
                            ),
                          ),
                        );
                      }),
                      _buildStatColumn(context, '${profileUser.following}', 'Following', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConnectionsScreen(
                              user: profileUser,
                              type: ConnectionListType.following,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Detail rows with icons: Location, Year/Branch, College
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'Jaipur, India',
                          context,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.school_outlined,
                          profileUser.academicLabel.isNotEmpty
                              ? profileUser.academicLabel
                              : 'Student',
                          context,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.business_rounded,
                          profileUser.college.isNotEmpty
                              ? profileUser.college
                              : 'Jaipur National University',
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Edit Profile or Follow Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isMe
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _openProfileEditor(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Edit Profile',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: _FollowButton(
                              isFollowing: profileUser.isFollowing,
                              isUpdating: usersP.isFollowUpdating(profileUser.id),
                              onTap: () async {
                                HapticFeedback.mediumImpact();
                                await usersP.toggleFollow(me.id, profileUser.id);
                                if (!context.mounted) return;
                                final error = usersP.followError(profileUser.id);
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(error),
                                        behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Aura reputation pill
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuraHistoryScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.bg2For(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.borderFor(context),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${profileUser.aura} Aura Reputation',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFor(context),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'View',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildBadgesSection(context, profileUser),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      if (profileUser.stack.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.bg2For(context),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.borderFor(context).withValues(alpha: 0.75),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.layers_rounded, 
                                    size: 16, color: Colors.teal.withValues(alpha: 0.8)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TECH STACK',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text3For(context),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 10,
                                children: profileUser.stack.map((s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.bg3For(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.borderFor(context),
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text2For(context),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (profileUser.githubHandle.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GitHubStatsCard(githubHandle: profileUser.githubHandle),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.dynamic_feed_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Recent Posts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textFor(context),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${posts.length}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text3For(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.text4For(context), size: 40),
                    const SizedBox(height: 16),
                    Text(
                      'No posts shared yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.text3For(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => PostCard(post: posts[i])
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (i * 50).ms),
                childCount: posts.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(BuildContext context, String count, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context))),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text3For(context))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.text2For(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.textFor(context).withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.textFor(context)),
      ),
    );
  }
}

class _AvatarActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AvatarActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textFor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.text3For(context),
          height: 1.35,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.text4For(context),
      ),
    );
  }
}

class _AvatarPreviewFallback extends StatelessWidget {
  final UserModel user;

  const _AvatarPreviewFallback({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      color: user.color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        user.avatar,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 88,
          fontWeight: FontWeight.w900,
          color: user.color,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isUpdating;
  final VoidCallback onTap;

  const _FollowButton(
      {required this.isFollowing,
      required this.isUpdating,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUpdating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : AppColors.primary,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color:
                isFollowing ? AppColors.borderFor(context) : AppColors.primary,
            width: 1.2,
          ),
        ),
        child: Text(
          isUpdating ? '...' : (isFollowing ? 'Following' : 'Follow'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: isFollowing ? AppColors.textFor(context) : Colors.white,
          ),
        ),
      ),
    );
  }
}
