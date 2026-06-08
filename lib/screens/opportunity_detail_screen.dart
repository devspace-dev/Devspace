import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final primaryColor = isHackathon ? Colors.purpleAccent : (isJob ? Colors.blueAccent : AppColors.primary);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: AppGradientBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, primaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, primaryColor),
                    const SizedBox(height: 32),
                    _buildMetaCards(context, primaryColor),
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, 'About the ${opportunity.type}'),
                    const SizedBox(height: 16),
                    Text(
                      opportunity.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.text2For(context),
                        letterSpacing: 0.1,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                    const SizedBox(height: 32),
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
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bgFor(context),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
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
            if (opportunity.bannerUrl != null && opportunity.bannerUrl!.isNotEmpty)
              Image.network(
                opportunity.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultBanner(primaryColor),
              )
            else
              _buildDefaultBanner(primaryColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    AppColors.bgFor(context).withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultBanner(Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          opportunity.type.toLowerCase() == 'hackathon' 
              ? Icons.terminal_rounded 
              : Icons.rocket_launch_rounded,
          size: 100,
          color: color.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBadge(
              label: opportunity.type.toUpperCase(),
              color: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            const SizedBox(width: 12),
            if (opportunity.organizer != null)
              Expanded(
                child: Text(
                  'by ${opportunity.organizer}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn().slideX(begin: -0.05),
        const SizedBox(height: 18),
        Text(
          opportunity.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
      ],
    );
  }

  Widget _buildMetaCards(BuildContext context, Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _MetaItem(
          icon: Icons.calendar_today_rounded,
          label: 'DATE',
          value: opportunity.date ?? 'TBA',
          color: primaryColor,
        ),
        _MetaItem(
          icon: Icons.location_on_rounded,
          label: 'LOCATION',
          value: opportunity.location ?? 'Remote',
          color: primaryColor,
        ),
        _MetaItem(
          icon: Icons.auto_awesome_rounded,
          label: 'REWARD',
          value: 'Experience',
          color: Colors.amber,
        ),
        _MetaItem(
          icon: Icons.shield_moon_rounded,
          label: 'AURA',
          value: '${opportunity.requiredAura} Needed',
          color: opportunity.locked ? Colors.redAccent : Colors.greenAccent,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.textFor(context),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildLockIncentive(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person_rounded, color: Colors.amber, size: 32),
          const SizedBox(height: 12),
          const Text(
            'High Aura Required',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete daily missions and engage with the community to unlock this opportunity.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.text3For(context), fontSize: 13),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActionFAB(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: AppButton(
        height: 60,
        backgroundColor: opportunity.locked ? AppColors.bg3For(context) : primaryColor,
        onPressed: opportunity.locked ? null : () => _handleRegister(context),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (opportunity.locked)
                const Icon(Icons.lock_rounded, size: 20, color: Colors.grey),
              if (opportunity.locked) const SizedBox(width: 10),
              Text(
                opportunity.locked 
                    ? 'LOCKED (${opportunity.requiredAura} AURA)' 
                    : (opportunity.type.toLowerCase() == 'hackathon' ? 'REGISTER FOR HACKATHON' : 'APPLY FOR ACCESS'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5);
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
    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.text4For(context),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textFor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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
