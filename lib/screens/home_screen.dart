import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../models/event_access_model.dart';
import 'explore_screen.dart';
import 'opportunity_detail_screen.dart';

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
      _MockHackathon(
        month: 'MAY',
        date: '24',
        title: 'Hack India 2025',
        mode: 'Hybrid',
        bannerUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
      ),
      _MockHackathon(
        month: 'MAY',
        date: '30',
        title: 'Build with AI',
        mode: 'Online',
        bannerUrl: 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop',
      ),
      _MockHackathon(
        month: 'JUN',
        date: '07',
        title: 'DevBattle 3.0',
        mode: 'Online',
        bannerUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&auto=format&fit=crop',
      ),
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
                            builder: (_) => const ExploreScreen(initialIndex: 1),
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
                            builder: (_) => const ExploreScreen(initialIndex: 1),
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
                            final parsedDate = _parseHackathonDate(hack.date, idx);
                            final m = parsedDate['month'] ?? 'MAY';
                            final d = parsedDate['day'] ?? '24';
                            return _buildHackathonCard(context, m, d, hack.title, hack.location ?? 'Online', isDark, hack.bannerUrl, hack);
                          },
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mockHackathons.length,
                          itemBuilder: (context, idx) {
                            final mock = mockHackathons[idx];
                            return _buildHackathonCard(context, mock.month, mock.date, mock.title, mock.mode, isDark, mock.bannerUrl, null);
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

  Widget _buildHackathonCard(BuildContext context, String month, String date, String title, String mode, bool isDark, String? bannerUrl, EventAccessModel? realHack) {
    final String displayBannerUrl;
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      displayBannerUrl = bannerUrl;
    } else {
      final hash = title.hashCode.abs();
      final fallbacks = [
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&auto=format&fit=crop',
      ];
      displayBannerUrl = fallbacks[hash % fallbacks.length];
    }

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
        width: 150,
        margin: const EdgeInsets.only(right: 12),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: displayBannerUrl,
                    height: 70,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 70,
                      color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F5),
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2E)]
                              : [const Color(0xFFE9ECEF), const Color(0xFFF8F9FA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(Icons.code_rounded, size: 24, color: AppColors.text3For(context)),
                    ),
                  ),
                  // Date overlay badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            month,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Hackathon Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                          height: 1.2,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text3For(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _parseHackathonDate(String? dateStr, [int index = 0]) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: index * 4 + 3));
      return {
        'month': _getMonthAbbreviation(futureDate.month),
        'day': futureDate.day.toString(),
      };
    }

    try {
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        var targetDate = parsedDate;
        final now = DateTime.now();
        if (targetDate.isBefore(now.add(const Duration(seconds: 1))) || 
            (targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day)) {
          targetDate = now.add(Duration(days: index * 4 + 3));
        }
        return {
          'month': _getMonthAbbreviation(targetDate.month),
          'day': targetDate.day.toString(),
        };
      }
    } catch (_) {}

    final cleaned = dateStr.replaceAll(RegExp(r'[,:\-\/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    final parts = cleaned.split(' ');
    final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
    final fullMonths = ['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'];

    String? foundMonth;
    String? foundDay;

    for (int i = 0; i < parts.length; i++) {
      final partLower = parts[i].toLowerCase();
      int monthIndex = months.indexOf(partLower.take(3));
      if (monthIndex == -1) {
        monthIndex = fullMonths.indexOf(partLower);
      }
      
      if (monthIndex != -1) {
        foundMonth = months[monthIndex].toUpperCase();
        if (i > 0) {
          final prevPart = parts[i - 1];
          if (RegExp(r'^\d+$').hasMatch(prevPart)) {
            foundDay = prevPart;
            break;
          }
        }
        if (i < parts.length - 1) {
          final nextPart = parts[i + 1];
          if (RegExp(r'^\d+$').hasMatch(nextPart)) {
            foundDay = nextPart;
            break;
          }
        }
      }
    }

    if (foundMonth != null && foundDay != null) {
      return {'month': foundMonth, 'day': foundDay};
    }

    if (foundMonth != null) {
      for (final part in parts) {
        if (RegExp(r'^\d+$').hasMatch(part)) {
          foundDay = part;
          break;
        }
      }
      return {'month': foundMonth, 'day': foundDay ?? '1'};
    }

    for (final part in parts) {
      if (RegExp(r'^\d+$').hasMatch(part) && part.length <= 2) {
        foundDay = part;
        break;
      }
    }

    final now = DateTime.now();
    final futureDate = now.add(Duration(days: index * 4 + 3));
    return {
      'month': foundMonth ?? _getMonthAbbreviation(futureDate.month),
      'day': foundDay ?? futureDate.day.toString(),
    };
  }

  String _getMonthAbbreviation(int monthIndex) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    if (monthIndex >= 1 && monthIndex <= 12) {
      return months[monthIndex - 1];
    }
    return 'MAY';
  }
}

class _MockHackathon {
  final String month;
  final String date;
  final String title;
  final String mode;
  final String? bannerUrl;

  const _MockHackathon({
    required this.month,
    required this.date,
    required this.title,
    required this.mode,
    this.bannerUrl,
  });
}

extension TakeExtension on String {
  String take(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
