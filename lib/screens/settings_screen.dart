import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/services/reward_feedback.dart';
import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_card.dart';
import '../core/widgets/ds_tag.dart';
import '../features/tour/services/tour_controller.dart';
import '../providers/auth_provider.dart';
import '../providers/posts_provider.dart';
import '../screens/founder_tools_screen.dart';
import '../screens/profile_setup_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/terms_and_conditions_screen.dart';
import '../services/backend_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<bool> _founderAccessFuture;
  bool _hapticsEnabled = RewardFeedback.isHapticsEnabledSync;

  @override
  void initState() {
    super.initState();
    _founderAccessFuture = BackendApiService.instance.hasFounderAccess();
    RewardFeedback.isHapticsEnabled().then((enabled) {
      if (mounted) setState(() => _hapticsEnabled = enabled);
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUserOrNull;
    if (me == null) {
      return const Scaffold(backgroundColor: Ds.ink);
    }

    final posts =
        Provider.of<PostsProvider?>(context, listen: true)?.postsForUser(me.id) ??
            const [];
    final totalLikes = posts.fold<int>(0, (sum, post) => sum + post.likes);

    return Scaffold(
      backgroundColor: Ds.ink,
      appBar: AppBar(
        backgroundColor: Ds.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Ds.bone),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'SETTINGS',
          style: DsText.h3.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _AccountCard(userName: me.name, handle: me.handle, email: me.email),
          const SizedBox(height: 12),
          _AnalyticsCard(
            postsCount: posts.length,
            totalLikes: totalLikes,
            aura: me.aura,
          ),
          const _SectionHeader(title: 'PROFILE'),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            subtitle: 'Update your builder identity and public details.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ProfileSetupScreen(mode: ProfileSetupMode.edit),
                ),
              );
            },
          ),
          const _SectionHeader(title: 'SAVED'),
          _SettingsTile(
            icon: Icons.bookmark_outline_rounded,
            title: 'Saved posts',
            subtitle: 'Revisit every post you bookmarked.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SavedPostsScreen(),
                ),
              );
            },
          ),
          const _SectionHeader(title: 'APP'),
          _SettingsTile(
            icon: Icons.vibration_rounded,
            title: 'Haptic feedback',
            subtitle:
                'Physical vibration on earning Aura, solving quests, and winning combat.',
            onTap: () {
              setState(() {
                _hapticsEnabled = !_hapticsEnabled;
                RewardFeedback.setHapticsEnabled(_hapticsEnabled);
                if (_hapticsEnabled) {
                  RewardFeedback.play(RewardKind.subtle);
                }
              });
            },
            trailing: Switch.adaptive(
              value: _hapticsEnabled,
              activeThumbColor: Ds.aura,
              activeTrackColor: Ds.aura.withValues(alpha: 0.3),
              onChanged: (val) {
                setState(() {
                  _hapticsEnabled = val;
                  RewardFeedback.setHapticsEnabled(val);
                  if (val) {
                    RewardFeedback.play(RewardKind.subtle);
                  }
                });
              },
            ),
          ),
          _SettingsTile(
            icon: Icons.replay_rounded,
            title: 'Replay tour',
            subtitle: 'Reset and walk through the feature tour with Glitch.',
            onTap: () async {
              final tour = context.read<TourController>();
              await tour.replayTour();
              if (context.mounted) {
                Navigator.of(context).pop();
                try {
                  GoRouter.maybeOf(context)?.go('/play');
                } catch (_) {
                  tour.routeNavigator?.call('/play');
                }
              }
            },
          ),
          if (me.isFounder)
            _SettingsTile(
              icon: Icons.developer_mode_rounded,
              title: 'Developer Dashboard',
              subtitle:
                  'Backend checks, device access, and internal system tools.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FounderToolsScreen(
                      mode: FounderToolsMode.developerDashboard,
                    ),
                  ),
                );
              },
            ),
          FutureBuilder<bool>(
            future: _founderAccessFuture,
            builder: (context, snapshot) {
              if (snapshot.data != true && !me.isFounder) {
                return const SizedBox.shrink();
              }

              return _SettingsTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Founder tools',
                subtitle:
                    'Manage events and daily challenges for the community.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FounderToolsScreen(
                        mode: FounderToolsMode.founderTools,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const _SectionHeader(title: 'ABOUT & LEGAL'),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms & Privacy',
            subtitle: 'Read the terms of service and in-app privacy policy.',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TermsAndConditionsScreen(),
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About DevSpace',
            subtitle: 'Why this app exists and what it is built for.',
            onTap: () => _showAbout(context),
          ),
          const _SectionHeader(title: 'DANGER ZONE'),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete account',
            subtitle: 'Permanently remove your profile and all your data.',
            isDanger: true,
            onTap: () => _handleDeleteAccount(context),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _handleLogout(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Ds.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Ds.hot.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Ds.hot, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SIGN OUT',
                    style: DsText.label.copyWith(
                      color: Ds.hot,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Ds.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Ds.border),
        ),
        title: Text(
          'SIGN OUT?',
          style: DsText.h3,
        ),
        content: Text(
          'You will return to the login screen on this device.',
          style: DsText.bodySm.copyWith(color: Ds.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: DsText.caption.copyWith(color: Ds.bone),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'SIGN OUT',
              style: DsText.caption.copyWith(
                color: Ds.hot,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Ds.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Ds.hot),
        ),
        title: Text(
          'DELETE ACCOUNT?',
          style: DsText.h3.copyWith(color: Ds.hot),
        ),
        content: Text(
          'This action is permanent. All your posts, profile, and aura points will be removed. You cannot undo this.',
          style: DsText.bodySm.copyWith(color: Ds.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'CANCEL',
              style: DsText.caption.copyWith(color: Ds.bone),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'DELETE PERMANENTLY',
              style: DsText.caption.copyWith(
                color: Ds.hot,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<AuthProvider>().deleteAccount();
        if (context.mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Ds.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Ds.border),
          ),
          title: Text('ABOUT DEVSPACE', style: DsText.h3),
          content: Text(
            'DevSpace is built for student developers to share progress, ask for help, and build a real builder identity inside their college community.',
            style: DsText.bodySm.copyWith(color: Ds.bone, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CLOSE',
                style: DsText.caption.copyWith(
                  color: Ds.aura,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        title,
        style: DsText.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Ds.muted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDanger;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DsCard(
        onTap: onTap,
        borderColor: isDanger ? Ds.hot.withValues(alpha: 0.4) : Ds.border,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Ds.ink,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDanger ? Ds.hot.withValues(alpha: 0.5) : Ds.border,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: isDanger ? Ds.hot : Ds.bone,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DsText.body.copyWith(
                      color: isDanger ? Ds.hot : Ds.bone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DsText.caption.copyWith(color: Ds.muted),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ] else ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDanger ? Ds.hot : Ds.muted,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final String userName;
  final String handle;
  final String email;

  const _AccountCard({
    required this.userName,
    required this.handle,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsTag('ACCOUNT', bg: Ds.border, fg: Ds.bone),
          const SizedBox(height: 12),
          Text(userName, style: DsText.h3),
          const SizedBox(height: 2),
          Text('@$handle', style: DsText.caption.copyWith(color: Ds.muted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Ds.ink,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Ds.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline_rounded, size: 16, color: Ds.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: DsText.bodySm.copyWith(color: Ds.bone),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final int postsCount;
  final int totalLikes;
  final int aura;

  const _AnalyticsCard({
    required this.postsCount,
    required this.totalLikes,
    required this.aura,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _InsightItem(
              label: 'POSTS',
              value: '$postsCount',
              icon: Icons.grid_view_rounded,
              accent: Ds.bone,
            ),
          ),
          Container(width: 1, height: 32, color: Ds.border),
          Expanded(
            child: _InsightItem(
              label: 'LIKES',
              value: '$totalLikes',
              icon: Icons.favorite_rounded,
              accent: Ds.hot,
            ),
          ),
          Container(width: 1, height: 32, color: Ds.border),
          Expanded(
            child: _InsightItem(
              label: 'AURA',
              value: '$aura',
              icon: Icons.bolt_rounded,
              accent: Ds.aura,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _InsightItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: accent),
              const SizedBox(width: 4),
              Text(
                value,
                style: DsText.h3.copyWith(fontSize: 16, color: accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: DsText.caption.copyWith(
            fontSize: 10,
            color: Ds.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
