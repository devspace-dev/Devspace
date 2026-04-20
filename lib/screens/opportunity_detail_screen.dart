import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: opportunity.link));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link. Copied to clipboard instead.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHackathon = opportunity.type.toLowerCase() == 'hackathon';
    final primaryColor = isHackathon ? Colors.purpleAccent : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: AppGradientBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, primaryColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isHackathon, primaryColor),
                    const SizedBox(height: 32),
                    _buildInfoSection(context, primaryColor),
                    const SizedBox(height: 32),
                    _buildDescriptionSection(context),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, primaryColor),
    );
  }

  Widget _buildAppBar(BuildContext context, Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bgFor(context),
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
                    Colors.black.withValues(alpha: 0.3),
                    AppColors.bgFor(context).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildDefaultBanner(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          opportunity.type.toLowerCase() == 'hackathon' 
              ? Icons.terminal_rounded 
              : Icons.auto_awesome_rounded,
          size: 80,
          color: color.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isHackathon, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBadge(
              label: opportunity.type.toUpperCase(),
              color: primaryColor,
            ),
            const SizedBox(width: 12),
            if (opportunity.organizer != null)
              Expanded(
                child: Text(
                  'by ${opportunity.organizer}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.text3For(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn().slideX(begin: -0.05),
        const SizedBox(height: 18),
        Text(
          opportunity.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
            letterSpacing: -1.0,
            height: 1.2,
          ),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Color primaryColor) {
    return AppGlassCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date & Time',
            value: opportunity.date ?? 'To be announced',
            color: primaryColor,
          ),
          const Divider(height: 32, thickness: 0.5),
          _InfoRow(
            icon: Icons.location_on_rounded,
            label: 'Location',
            value: opportunity.location ?? 'Online / Remote',
            color: primaryColor,
          ),
          const Divider(height: 32, thickness: 0.5),
          _InfoRow(
            icon: Icons.star_rounded,
            label: 'Aura Required',
            value: '${opportunity.requiredAura} Points',
            color: Colors.amber,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDescriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About the ${opportunity.type}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          opportunity.description,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.text2For(context),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildBottomAction(BuildContext context, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: AppColors.bgFor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AppButton(
        height: 56,
        backgroundColor: primaryColor,
        onPressed: opportunity.locked ? null : () => _handleRegister(context),
        child: Center(
          child: Text(
            opportunity.locked 
                ? 'Unlock with ${opportunity.requiredAura} Aura' 
                : (opportunity.type.toLowerCase() == 'hackathon' ? 'Register Now' : 'Apply Now'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.text3For(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textFor(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
