import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_access_model.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';

class OpportunityDetailScreen extends StatelessWidget {
  final EventAccessModel opportunity;

  const OpportunityDetailScreen({super.key, required this.opportunity});

  Future<void> _handleRegister(BuildContext context) async {
    if (opportunity.link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration link not available yet.')),
      );
      return;
    }

    final uri = Uri.tryParse(opportunity.link);
    if (uri != null && await canLaunchUrl(uri)) {
      HapticFeedback.heavyImpact();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: opportunity.link));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard.')),
        );
      }
    }
  }

  void _handleShare() {
    Share.share(
      'Check out this ${opportunity.type} on DevSpace: ${opportunity.title}\n\n${opportunity.link}',
      subject: 'DevSpace Opportunity',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHackathon = opportunity.type.toLowerCase() == 'hackathon';
    final isJob = opportunity.type.toLowerCase() == 'job' || opportunity.requiredAura > 100;
    // Replace pink/purple with DevSpace Premium Orange/Teal/Blue palette
    final primaryColor = isHackathon 
        ? AppColors.primary 
        : (isJob ? const Color(0xFF007AFF) : const Color(0xFF10B981));

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: AppGradientBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, primaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(context, primaryColor),
                    const SizedBox(height: 24),
                    _buildMetaCards(context, primaryColor),
                    const SizedBox(height: 28),
                    _buildSectionTitle(context, 'About the ${opportunity.type}'),
                    const SizedBox(height: 14),
                    _buildDescriptionCard(context),
                    const SizedBox(height: 28),
                    if (opportunity.locked) _buildLockIncentive(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildActionFAB(context, primaryColor),
    );
  }

  Widget _buildAppBar(BuildContext context, Color primaryColor) {
    final hasBanner = opportunity.bannerUrl != null && opportunity.bannerUrl!.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bgFor(context),
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
          ),
          onPressed: _handleShare,
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasBanner)
              _isLogoUrl(opportunity.bannerUrl)
                  ? _buildLogoBanner(context, opportunity.bannerUrl!, isDark)
                  : CachedNetworkImage(
                      imageUrl: opportunity.bannerUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _buildDefaultBanner(context, primaryColor),
                    )
            else
              _buildDefaultBanner(context, primaryColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    AppColors.bgFor(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(BuildContext context, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  color.withValues(alpha: 0.25),
                  AppColors.bg2Dark,
                  color.withValues(alpha: 0.05),
                ]
              : [
                  color.withValues(alpha: 0.15),
                  Colors.white,
                  color.withValues(alpha: 0.02),
                ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              opportunity.type.toLowerCase() == 'hackathon'
                  ? Icons.terminal_rounded
                  : Icons.rocket_launch_rounded,
              size: 150,
              color: color.withValues(alpha: 0.06),
            ),
          ),
          Hero(
            tag: 'opp_logo_${opportunity.id}',
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildBrandLogo(opportunity.organizer ?? '', size: 68),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(String organizer, {double size = 44}) {
    final name = organizer.toLowerCase();
    if (name.contains('microsoft')) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(color: const Color(0xFFF25022)),
            Container(color: const Color(0xFF7FBA00)),
            Container(color: const Color(0xFF00A4EF)),
            Container(color: const Color(0xFFFFB900)),
          ],
        ),
      );
    } else if (name.contains('nasa')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF0C2340),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'NASA',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (name.contains('postman')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFFFF6C37),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.rocket_launch_rounded,
          color: Colors.white,
          size: size * 0.45,
        ),
      );
    } else if (name.contains('google')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.blue,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (name.contains('mlh')) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF004851),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          'MLH',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.orange.shade50,
      child: Text(
        organizer.isNotEmpty ? organizer[0].toUpperCase() : 'O',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  opportunity.type.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (opportunity.organizer != null) ...[
                _buildBrandLogo(opportunity.organizer!, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    opportunity.organizer!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.text2For(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ).animate().fadeIn().slideX(begin: -0.05),
          const SizedBox(height: 16),
          Text(
            opportunity.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textFor(context),
              letterSpacing: -0.8,
              height: 1.25,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
        ],
      ),
    );
  }

  Widget _buildMetaCards(BuildContext context, Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _MetaItem(
          icon: Icons.calendar_today_rounded,
          label: 'DEADLINE',
          value: _getFriendlyDeadline(opportunity),
          color: primaryColor,
        ),
        _MetaItem(
          icon: Icons.location_on_rounded,
          label: 'LOCATION',
          value: opportunity.location ?? 'Remote',
          color: primaryColor,
        ),
        const _MetaItem(
          icon: Icons.emoji_events_rounded,
          label: 'REWARD',
          value: 'Swags & Certs',
          color: Colors.amber,
        ),
        _MetaItem(
          icon: Icons.shield_moon_rounded,
          label: 'REQUIRED AURA',
          value: opportunity.requiredAura > 0 ? '${opportunity.requiredAura} Needed' : 'No Minimum',
          color: opportunity.locked ? const Color(0xFFFF416C) : const Color(0xFF00FFCC),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textFor(context),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildDescriptionText(BuildContext context, String text) {
    final paragraphs = text.split(RegExp(r'\r?\n+'));
    
    if (paragraphs.length == 1 && text.length > 120) {
      final sentenceRegex = RegExp(r'\.\s+(?=[A-Z])');
      final sentences = text.split(sentenceRegex);
      
      if (sentences.length > 1) {
        final List<Widget> children = [];
        for (int i = 0; i < sentences.length; i++) {
          var s = sentences[i].trim();
          if (s.isEmpty) continue;
          if (!s.endsWith('.') && i < sentences.length - 1) {
            s += '.';
          }
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.6,
                        color: AppColors.text2For(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((para) {
        final trimmed = para.trim();
        if (trimmed.isEmpty) return const SizedBox.shrink();
        
        final isBullet = trimmed.startsWith('•') || trimmed.startsWith('-') || trimmed.startsWith('*');
        final cleanText = isBullet ? trimmed.substring(1).trim() : trimmed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
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
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  cleanText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.6,
                    color: AppColors.text2For(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191920) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
        ),
      ),
      child: _buildDescriptionText(context, opportunity.description),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }

  Widget _buildLockIncentive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person_rounded, color: Colors.amber, size: 28),
          const SizedBox(height: 10),
          Text(
            'High Aura Required',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete daily matches and engage with other builders to earn aura and unlock premium opportunities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: AppColors.text3For(context), fontSize: 12),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActionFAB(BuildContext context, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!opportunity.locked)
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: AppButton(
          height: 56,
          backgroundColor: opportunity.locked ? AppColors.bg3For(context) : primaryColor,
          onPressed: opportunity.locked ? null : () => _handleRegister(context),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (opportunity.locked) ...[
                  const Icon(Icons.lock_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                ],
                Text(
                  opportunity.locked 
                      ? 'LOCKED (${opportunity.requiredAura} AURA)' 
                      : (opportunity.type.toLowerCase() == 'hackathon' ? 'REGISTER NOW' : 'APPLY TO ACCESS'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5);
  }

  bool _isLogoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lower = url.toLowerCase();
    return lower.contains('150x150') ||
        lower.contains('/logo/') ||
        lower.endsWith('_logo.jpg') ||
        lower.endsWith('_logo.png') ||
        lower.contains('organisation_image') ||
        lower.contains('organization_image');
  }

  Widget _buildLogoBanner(BuildContext context, String logoUrl, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ColorFilter.mode(
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
                BlendMode.srcOver,
              ),
              child: const SizedBox(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: CachedNetworkImage(
              imageUrl: logoUrl,
              fit: BoxFit.contain,
              errorWidget: (context, url, error) => const Icon(
                Icons.image_outlined,
                color: Colors.grey,
                size: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFriendlyDeadline(EventAccessModel opportunity) {
    if (opportunity.date != null && opportunity.date!.trim().isNotEmpty) {
      return opportunity.date!;
    }
    if (opportunity.endDate != null && opportunity.endDate!.trim().isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(opportunity.endDate!);
        if (parsed != null) {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
        }
      } catch (_) {}
    }
    return 'TBA';
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text4For(context),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textFor(context),
                    fontSize: 12,
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
}
