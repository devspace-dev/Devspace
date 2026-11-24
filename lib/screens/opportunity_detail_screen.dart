import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/colors.dart';
import '../core/theme/text.dart';
import '../core/widgets/ds_button.dart';
import '../core/widgets/ds_card.dart';
import '../core/widgets/ds_tag.dart';
import '../models/event_access_model.dart';
import '../utils/opportunity_banner.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final EventAccessModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  Future<void> _handleRegister(BuildContext context) async {
    final rawLink = opportunity.link.trim();
    if (rawLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration link not available yet.', style: DsText.label.copyWith(color: Ds.ink)),
          backgroundColor: Ds.aura,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final normalizedLink = rawLink.contains('://') ? rawLink : 'https://$rawLink';
    final uri = Uri.tryParse(normalizedLink);
    final isAllowedScheme = uri != null &&
        uri.hasAuthority &&
        (uri.scheme.toLowerCase() == 'https' ||
            uri.scheme.toLowerCase() == 'http');

    if (isAllowedScheme) {
      try {
        HapticFeedback.heavyImpact();
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
        final fallbackLaunched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (fallbackLaunched) return;
      } catch (_) {}
    }

    await Clipboard.setData(ClipboardData(text: normalizedLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link copied to clipboard.', style: DsText.label.copyWith(color: Ds.ink)),
          backgroundColor: Ds.aura,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    // ignore: deprecated_member_use
    Share.share(
      'Check out this ${opportunity.type} on DevSpace: ${opportunity.title}\n\n${opportunity.link}',
      subject: 'DevSpace Opportunity: ${opportunity.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHackathon = opportunity.type.toLowerCase() == 'hackathon';
    final hasBanner = opportunity.bannerUrl != null &&
        opportunity.bannerUrl!.trim().isNotEmpty &&
        !isPlaceholderPhotoUrl(opportunity.bannerUrl);

    return Scaffold(
      backgroundColor: Ds.ink,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, hasBanner),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(context),
                  const SizedBox(height: 16),
                  _buildMetaGrid(context),
                  const SizedBox(height: 24),
                  Text(
                    'ABOUT THIS ${opportunity.type.toUpperCase()}',
                    style: DsText.h3.copyWith(fontSize: 18, color: Ds.bone),
                  ),
                  const SizedBox(height: 12),
                  _buildDescriptionCard(context),
                  if (opportunity.locked) ...[
                    const SizedBox(height: 20),
                    _buildLockIncentive(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildStickyActionBar(context, isHackathon),
    );
  }

  Widget _buildAppBar(BuildContext context, bool hasBanner) {
    return SliverAppBar(
      expandedHeight: hasBanner ? 220 : 100,
      pinned: true,
      backgroundColor: Ds.ink,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Ds.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Ds.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Ds.bone, size: 16),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _handleShare,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Ds.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Ds.border),
              ),
              child: const Icon(Icons.share_rounded, color: Ds.bone, size: 18),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: hasBanner
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: opportunity.bannerUrl!,
                    fit: isLogoPhotoUrl(opportunity.bannerUrl) ? BoxFit.contain : BoxFit.cover,
                    memCacheWidth: 1080,
                    memCacheHeight: 480,
                    errorWidget: (_, __, ___) => _buildFallbackBanner(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Ds.ink.withValues(alpha: 0.4),
                          Colors.transparent,
                          Ds.ink,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _buildFallbackBanner(),
      ),
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      color: Ds.surface,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.terminal_rounded, color: Ds.aura, size: 28),
            const SizedBox(width: 8),
            Text(
              'DEVSPACE // EVENT',
              style: DsText.h3.copyWith(color: Ds.muted, fontSize: 16, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final hasOrganizer = opportunity.organizer != null && opportunity.organizer!.trim().isNotEmpty;

    return DsCard(
      leftBar: opportunity.locked ? Ds.hot : Ds.mint,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DsTag(
                opportunity.type.toUpperCase(),
                bg: Ds.border,
                fg: Ds.bone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            opportunity.title.toUpperCase(),
            style: DsText.h2.copyWith(fontSize: 26, color: Ds.bone, height: 1.15),
          ),
          if (hasOrganizer) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.apartment_rounded, size: 16, color: Ds.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    opportunity.organizer!,
                    style: DsText.caption.copyWith(color: Ds.muted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildMetaGrid(BuildContext context) {
    final timeLeft = _getTimeLeft(opportunity);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildMetaTile(
          icon: Icons.calendar_today_rounded,
          label: 'DEADLINE',
          value: _getFriendlyDeadline(opportunity),
          accentColor: Ds.aura,
        ),
        _buildMetaTile(
          icon: Icons.location_on_rounded,
          label: 'LOCATION',
          value: opportunity.location ?? 'Remote',
          accentColor: Ds.mint,
        ),
        _buildMetaTile(
          icon: timeLeft != null ? Icons.timer_outlined : Icons.tag_rounded,
          label: timeLeft != null ? 'TIME LEFT' : 'TYPE',
          value: timeLeft ?? opportunity.type.toUpperCase(),
          accentColor: timeLeft != null ? Ds.hot : Ds.muted,
        ),
        _buildMetaTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'ACCESS',
          value: 'OPEN',
          accentColor: Ds.mint,
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 250.ms);
  }

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Ds.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Ds.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: DsText.caption.copyWith(
                    color: Ds.muted,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DsText.label.copyWith(
                    color: Ds.bone,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    return DsCard(
      padding: const EdgeInsets.all(16),
      child: _buildDescriptionText(context, opportunity.description),
    ).animate().fadeIn(delay: 200.ms, duration: 250.ms);
  }

  Widget _buildDescriptionText(BuildContext context, String text) {
    if (text.trim().isEmpty) {
      return Text(
        'No detailed description provided for this opportunity.',
        style: DsText.bodySm.copyWith(color: Ds.muted),
      );
    }

    final paragraphs = text.split(RegExp(r'\r?\n+'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final trimmed = para.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();

        final isBullet = trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*');
        final cleanText = isBullet ? trimmed.substring(1).trim() : trimmed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBullet)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Ds.aura,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  cleanText,
                  style: DsText.body.copyWith(
                    fontSize: 14,
                    height: 1.55,
                    color: Ds.bone,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLockIncentive(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildStickyActionBar(BuildContext context, bool isHackathon) {
    final hasLink = opportunity.link.trim().isNotEmpty;
    final label = !hasLink
        ? 'REGISTRATION CLOSED'
        : (isHackathon ? 'REGISTER NOW' : 'APPLY TO ACCESS');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Ds.ink,
        border: Border(
          top: BorderSide(color: Ds.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: DsButton(
            label: label,
            kind: DsButtonKind.aura,
            onPressed: hasLink ? () => _handleRegister(context) : null,
          ),
        ),
      ),
    );
  }

  String _getFriendlyDeadline(EventAccessModel opportunity) {
    final parsed = DateTime.tryParse(opportunity.endDate ?? '')?.toLocal();
    if (parsed != null) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    }
    if (opportunity.date != null && opportunity.date!.trim().isNotEmpty) {
      return opportunity.date!;
    }
    return 'TBA';
  }

  String? _getTimeLeft(EventAccessModel opportunity) {
    final end = DateTime.tryParse(opportunity.endDate ?? '')?.toLocal();
    if (end == null) return null;
    final now = DateTime.now();
    final days = DateTime(end.year, end.month, end.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return 'Ended';
    if (days == 0) return 'Closes today';
    if (days == 1) return 'Closes tomorrow';
    return '$days days left';
  }
}
