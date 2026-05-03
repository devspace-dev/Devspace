import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

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
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textFor(dialogContext),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipOval(
                      child: user.isImageAvatar
                          ? Image.network(
                              StorageService.instance.resolvePublicUrl(user.avatar),
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _AvatarPreviewFallback(user: user),
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
    final isMe = userId == null || userId == me.id;
    final user = isMe ? me : usersP.getUserById(userId!);

    if (!isMe && user == null && usersP.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        body: const SafeArea(child: ProfileSkeleton()),
      );
    }

    if (!isMe && user == null && usersP.error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgFor(context),
        appBar: AppBar(backgroundColor: AppColors.bgFor(context)),
        body: AppErrorState(
          title: 'Profile unavailable',
          message: usersP.error!,
          actionLabel: 'Retry',
          onAction: usersP.refreshUsers,
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
          onAction: usersP.refreshUsers,
        ),
      );
    }

    final profileUser = user ?? me;
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.bg2For(context).withValues(alpha: 0.8),
                          AppColors.bg3For(context),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgFor(context).withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.borderFor(context).withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          isMe ? 'My Developer Profile' : 'Developer Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text2For(context),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      // Centered Avatar
                      Center(
                        child: GestureDetector(
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
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: UserAvatar(
                              user: profileUser,
                              size: 110, // Slightly larger for centering
                              showRing: false,
                              showStory: false,
                            ),
                          ),
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
                                fontWeight: FontWeight.w900,
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
                            const Icon(Icons.verified_rounded, color: Colors.amber, size: 20),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Handle and Followers
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConnectionsScreen(
                                user: profileUser,
                                type: ConnectionListType.followers,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'u/${profileUser.handle} • ${profileUser.followers} followers',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text3For(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mini Chips (Roles, College)
                      Center(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (profileUser.roles.isNotEmpty)
                              _ProfileMiniChip(
                                icon: Icons.draw_rounded,
                                label: profileUser.roles.first,
                              ),
                            if (profileUser.academicLabel.isNotEmpty)
                              _ProfileMiniChip(
                                icon: Icons.school_rounded,
                                label: profileUser.academicLabel,
                              ),
                            if (profileUser.college.isNotEmpty)
                              _ProfileMiniChip(
                                icon: Icons.apartment_rounded,
                                label: profileUser.college,
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Action Button (Edit or Follow)
                      if (isMe)
                        GestureDetector(
                          onTap: () => _openProfileEditor(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Edit Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else
                        _FollowButton(
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    profileUser.bio.isEmpty
                        ? 'Student builder turning class projects into a real portfolio.'
                        : profileUser.bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.text2For(context),
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuraHistoryScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Colors.amber,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${profileUser.aura} aura reputation',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textFor(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.text3For(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bg2For(context).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ProfileHeroStat(
                            value: '${profileUser.currentStreak}',
                            label: 'Momentum',
                            icon: Icons.local_fire_department_rounded,
                            accentColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProfileHeroStat(
                            value: '${posts.length}',
                            label: 'Showcase',
                            icon: Icons.grid_view_rounded,
                            accentColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProfileHeroStat(
                            value: '${profileUser.following}',
                            label: 'Network',
                            icon: Icons.hub_rounded,
                            accentColor: Colors.teal,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ConnectionsScreen(
                                  user: profileUser,
                                  type: ConnectionListType.following,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ProfileHeroStat(
                            value: '${profileUser.followers}',
                            label: 'Reach',
                            icon: Icons.trending_up_rounded,
                            accentColor: Colors.pinkAccent,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ConnectionsScreen(
                                  user: profileUser,
                                  type: ConnectionListType.followers,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.bg2For(context),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.rocket_launch_rounded, 
                                  size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                                const SizedBox(width: 8),
                                Text(
                                  profileUser.building.isNotEmpty &&
                                          profileUser.building != 'Not set'
                                      ? 'CURRENTLY BUILDING'
                                      : 'PORTFOLIO FOCUS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text3For(context),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              profileUser.building.isNotEmpty &&
                                      profileUser.building != 'Not set'
                                  ? profileUser.building
                                  : 'Shipping projects, learning in public, and building a stronger student developer identity.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textFor(context),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                          child: Icon(Icons.dynamic_feed_rounded, color: AppColors.primary, size: 20),
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

class _ProfileMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderFor(context).withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.text3For(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text2For(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accentColor;

  const _ProfileHeroStat({
    required this.value,
    required this.label,
    this.onTap,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.bgFor(context).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          children: [
            if (icon != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: (accentColor ?? AppColors.primary).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 15,
                  color: accentColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textFor(context),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text3For(context),
                ),
              ),
            ),
          ],
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
