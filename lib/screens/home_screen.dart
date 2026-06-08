import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../models/event_access_model.dart';
import 'explore_screen.dart';
import 'opportunity_detail_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  void scrollToTopAndRefresh() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authP = context.watch<AuthProvider>();
    final user = authP.currentUserOrNull;
    final engagementP = context.watch<EngagementProvider>();
    final allEvents = engagementP.events;

    final name = user?.name ?? 'Builder';
    final aura = user?.aura ?? 0;
    final currentProject = user?.building.isNotEmpty == true ? user!.building : 'DevConnect';

    // Filter opportunities & hackathons
    final realOpportunities = allEvents.where((e) => e.type.toLowerCase() != 'hackathon').toList();
    final realHackathons = allEvents.where((e) => e.type.toLowerCase() == 'hackathon').toList();

    // Mock opportunities for UI fidelity matching Screen 2
    final mockOpportunities = [
      EventAccessModel(
        id: 'mock_gsoc',
        title: 'Google Summer of Code 2025',
        description: 'Google Summer of Code is a global program focused on bringing new contributors into open source software development.',
        requiredAura: 0,
        link: 'https://summerofcode.withgoogle.com/',
        type: 'Program',
        unlocked: true,
        locked: false,
        organizer: 'Google',
        location: 'Remote',
        date: 'Applications close in 3 days',
      ),
      EventAccessModel(
        id: 'mock_mlsa',
        title: 'Microsoft Learn Student Ambassadors',
        description: 'Be a leader in your community, build technical skills, and share technology with peers.',
        requiredAura: 0,
        link: 'https://mvp.microsoft.com/studentambassadors',
        type: 'Ambassador',
        unlocked: true,
        locked: false,
        organizer: 'Microsoft',
        location: 'Worldwide',
        date: 'Applications close in 12 days',
      ),
    ];

    // Mock hackathons for UI fidelity matching Screen 2
    final mockHackathons = [
      _MockHackathon(month: 'MAY', date: '24', title: 'Hack India 2025', mode: 'Hybrid'),
      _MockHackathon(month: 'MAY', date: '30', title: 'Build with AI', mode: 'Online'),
      _MockHackathon(month: 'JUN', date: '07', title: 'DevBattle 3.0', mode: 'Online'),
    ];

    final displayOpportunities = realOpportunities.isNotEmpty ? realOpportunities : mockOpportunities;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.wait([
              authP.refreshUsers(),
              engagementP.fetchOverview(),
            ]);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Greeting Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Evening,',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppColors.text3For(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$name 👋',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            color: AppColors.textFor(context),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Continue Building Card
                Text(
                  'Continue Building',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3For(context),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bg2Dark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderFor(context).withValues(alpha: 0.8),
                    ),
                    boxShadow: !isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.code_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentProject,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textFor(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Real-time dev networking',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.text3For(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                value: 0.6,
                                minHeight: 6,
                                backgroundColor: Color(0xFFF1F3F5),
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '60%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text3For(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Opportunities For You Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Opportunities for you',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExploreScreen(initialIndex: 0),
                          ),
                        );
                      },
                      child: Text(
                        'View all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...displayOpportunities.take(2).map((opp) => _buildOpportunityCard(context, opp, isDark)),
                const SizedBox(height: 24),

                // 4. Upcoming Hackathons Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Hackathons',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textFor(context),
                        letterSpacing: -0.4,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExploreScreen(initialIndex: 0),
                          ),
                        );
                      },
                      child: Text(
                        'View all',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: realHackathons.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: realHackathons.length,
                          itemBuilder: (context, idx) {
                            final hack = realHackathons[idx];
                            // Parse simple month / date representation from date string
                            String m = 'MAY';
                            String d = '24';
                            if (hack.date != null && hack.date!.contains(' ')) {
                              final parts = hack.date!.split(' ');
                              if (parts.length >= 2) {
                                m = parts[1].toUpperCase().take(3);
                                d = parts[0];
                              }
                            }
                            return _buildHackathonCard(context, m, d, hack.title, hack.location ?? 'Online', isDark, hack);
                          },
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mockHackathons.length,
                          itemBuilder: (context, idx) {
                            final mock = mockHackathons[idx];
                            return _buildHackathonCard(context, mock.month, mock.date, mock.title, mock.mode, isDark, null);
                          },
                        ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpportunityCard(BuildContext context, EventAccessModel opp, bool isDark) {
    String initial = opp.organizer?.isNotEmpty == true ? opp.organizer![0].toUpperCase() : 'G';
    Color circleColor = opp.organizer?.toLowerCase() == 'google' ? Colors.blue.shade50 : (opp.organizer?.toLowerCase() == 'microsoft' ? Colors.orange.shade50 : Colors.red.shade50);
    Color textColor = opp.organizer?.toLowerCase() == 'google' ? Colors.blue : (opp.organizer?.toLowerCase() == 'microsoft' ? Colors.orange : Colors.red);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpportunityDetailScreen(opportunity: opp),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.8),
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: circleColor,
                  child: Text(
                    initial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opp.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Tags row
                      Row(
                        children: [
                          _buildTag(context, opp.location ?? 'Remote'),
                          const SizedBox(width: 8),
                          _buildTag(context, 'Stipend'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.text3For(context),
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: AppColors.borderFor(context).withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  opp.requiredAura > 0 ? '${opp.requiredAura} Aura' : '\$5000',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      opp.date ?? 'Applications close soon',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF5E00), // Warm premium accent red-orange
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: AppColors.text3For(context),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.text3For(context),
        ),
      ),
    );
  }

  Widget _buildHackathonCard(BuildContext context, String month, String date, String title, String mode, bool isDark, EventAccessModel? realHack) {
    return GestureDetector(
      onTap: () {
        if (realHack != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OpportunityDetailScreen(opportunity: realHack),
            ),
          );
        }
      },
      child: Container(
        width: 125,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.8),
          ),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month / Day Indicator
            Center(
              child: Column(
                children: [
                  Text(
                    month,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text3For(context),
                    ),
                  ),
                  Text(
                    date,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textFor(context),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              mode,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.text3For(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockHackathon {
  final String month;
  final String date;
  final String title;
  final String mode;

  const _MockHackathon({
    required this.month,
    required this.date,
    required this.title,
    required this.mode,
  });
}

extension TakeExtension on String {
  String take(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
