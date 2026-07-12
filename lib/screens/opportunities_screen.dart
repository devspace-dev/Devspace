import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/event_access_model.dart';
import '../providers/engagement_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import 'opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Hackathons',
    'Internships',
    'Fellowships',
    'Scholarships',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final myAura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Consumer<EngagementProvider>(
          builder: (context, provider, _) {
            Widget sliverContent;

            if (provider.isLoading && provider.events.isEmpty) {
              sliverContent = _buildLoadingSkeleton();
            } else if (provider.error != null && provider.events.isEmpty) {
              sliverContent = _buildErrorState(
                  context, provider.error!, provider.fetchOverview);
            } else {
              final mergedEvents = _getMergedEvents(provider.events);

              // Filter logic
              final filtered = mergedEvents.where((e) {
                // 1. Search Query Filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  final matchesTitle = e.title.toLowerCase().contains(query);
                  final matchesDesc =
                      e.description.toLowerCase().contains(query);
                  final matchesOrg =
                      (e.organizer?.toLowerCase() ?? '').contains(query);
                  if (!matchesTitle && !matchesDesc && !matchesOrg)
                    return false;
                }

                // 2. Category Pill Filter
                if (_selectedCategory == 'All') return true;
                if (_selectedCategory == 'Hackathons') {
                  return e.type.toLowerCase() == 'hackathon';
                }
                if (_selectedCategory == 'Internships') {
                  return e.type.toLowerCase() == 'internship' ||
                      e.title.toLowerCase().contains('intern');
                }
                if (_selectedCategory == 'Fellowships') {
                  return e.type.toLowerCase() == 'fellowship' ||
                      e.type.toLowerCase() == 'ambassador' ||
                      e.title.toLowerCase().contains('fellow') ||
                      e.title.toLowerCase().contains('ambassador');
                }
                if (_selectedCategory == 'Scholarships') {
                  return e.type.toLowerCase() == 'scholarship' ||
                      e.title.toLowerCase().contains('scholar');
                }

                return true;
              }).toList();

              if (filtered.isEmpty) {
                sliverContent = _buildEmptyState();
              } else {
                sliverContent = SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return _OpportunityCard(
                          item: item,
                          myAura: myAura,
                          tags: _getTagsForOpportunity(item),
                          brandLogo: _buildBrandLogo(item.organizer ?? '', item.bannerUrl),
                        )
                            .animate()
                            .fadeIn(delay: (index * 50).ms)
                            .slideY(begin: 0.05, curve: Curves.easeOutCubic);
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              }
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;
            return RefreshIndicator.adaptive(
              onRefresh: () =>
                  provider.fetchOverview(forceChallengeRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, canPop)),
                  SliverToBoxAdapter(child: _buildSearchHeader(context)),
                  SliverToBoxAdapter(child: _buildCategorySelector(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  if (_searchQuery.isEmpty && (_selectedCategory == 'All' || _selectedCategory == 'Hackathons'))
                    SliverToBoxAdapter(child: _buildUpcomingHackathonsSection(context, provider.events, isDark)),
                  sliverContent,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canPop) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.only(top: 6, right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.bg2Dark
                      : const Color(0xFFF1F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textFor(context),
                  size: 16,
                ),
              ),
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore\nOpportunities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find the right opportunity to level up.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppColors.text3For(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textFor(context),
            fontSize: 14,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: 'Search opportunities...',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.text3For(context),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.text3For(context),
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : Icon(
                    Icons.tune_rounded,
                    color: AppColors.text3For(context),
                    size: 20,
                  ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedCategory = cat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.bg3Dark : const Color(0xFFF1F3F5)),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.text2Dark
                          : const Color(0xFF495057)),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<EventAccessModel> _getMergedEvents(List<EventAccessModel> serverEvents) {
    final screenshotMocks = [
      const EventAccessModel(
        id: 'mlsa_opp',
        title: 'Microsoft Learn Student Ambassadors',
        description:
            'Be a leader in your community, build technical skills, and share technology with peers. As a Student Ambassador, you will get access to Microsoft resources, Azure credits, mentorship from industry experts, and a global network of student leaders. You will host workshops, build communities, and gain hands-on experience with cutting-edge tech.\n\nBenefits include free Microsoft certification exams, exclusive swags, and invitations to regional summits.',
        requiredAura: 0,
        link: 'https://mvp.microsoft.com/studentambassadors',
        type: 'Ambassador',
        unlocked: true,
        locked: false,
        organizer: 'Microsoft',
        location: 'Worldwide',
        date: 'Applications close in 5 days',
        bannerUrl:
            'https://images.unsplash.com/photo-1625014020903-e329f58a4990?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'nasa_opp',
        title: 'NASA Internships Fall 2025',
        description:
            'NASA Internships are competitive awards to support educational opportunities that provide unique NASA-related research and operational experiences. Interns work under the guidance of NASA mentors on real projects, ranging from aerospace engineering and astrophysics to software development and earth sciences.\n\nThis is an unparalleled opportunity to contribute directly to space exploration missions, learn from world-renowned scientists, and build a stellar network in the space tech industry.',
        requiredAura: 0,
        link: 'https://intern.nasa.gov/',
        type: 'Internship',
        unlocked: true,
        locked: false,
        organizer: 'NASA',
        location: 'On-site',
        date: 'Applications close in 12 days',
        bannerUrl:
            'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'postman_opp',
        title: 'Postman Student Expert Program',
        description:
            'Postman Student Experts are student leaders who teach their peers about APIs and Postman. Through this self-paced program, you\'ll learn the essentials of API design, testing, and documentation using Postman.\n\nOnce certified, you\'ll unlock access to exclusive Postman swags, invitations to developer events, and resources to host API workshops on your campus. Boost your developer profile and gain official recognition from Postman.',
        requiredAura: 0,
        link: 'https://www.postman.com/student-program/student-expert/',
        type: 'Program',
        unlocked: true,
        locked: false,
        organizer: 'Postman',
        location: 'Remote',
        date: 'Applications close in 7 days',
        bannerUrl:
            'https://images.unsplash.com/photo-1618401471353-b98aedd07871?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'mlh_opp',
        title: 'MLH Fellowship',
        description:
            'A remote internship alternative for software developers to build open-source projects. The MLH Fellowship is a 12-week program where students collaborate with maintainers on major open-source projects (like React, Jest, and Dask) used by millions.\n\nYou\'ll receive an educational stipend, participate in daily standups, receive code reviews, and learn from senior engineers. Perfect for building a strong portfolio and starting your career in open source.',
        requiredAura: 0,
        link: 'https://fellowship.mlh.io/',
        type: 'Fellowship',
        unlocked: true,
        locked: false,
        organizer: 'MLH',
        location: 'Remote',
        date: 'Applications close in 15 days',
        bannerUrl:
            'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'gsoc_opp',
        title: 'Google Summer of Code 2025',
        description:
            'Google Summer of Code is a global program focused on bringing new contributors into open source software development. GSoC contributors work on a 12+ week programming project with an open source organization under the guidance of mentors.\n\nContributors learn about open source culture, get paid a stipend based on their location, and receive invaluable feedback on their code. It is one of the most prestigious open-source initiatives worldwide.',
        requiredAura: 0,
        link: 'https://summerofcode.withgoogle.com/',
        type: 'Program',
        unlocked: true,
        locked: false,
        organizer: 'Google',
        location: 'Remote',
        date: 'Applications close in 20 days',
        bannerUrl:
            'https://images.unsplash.com/photo-1572021335469-31706a17aaef?w=800&auto=format&fit=crop',
      ),
    ];

    final merged = List<EventAccessModel>.from(serverEvents);
    for (final mock in screenshotMocks) {
      if (!merged
          .any((e) => e.title.toLowerCase() == mock.title.toLowerCase())) {
        merged.add(mock);
      }
    }
    return merged;
  }

  List<String> _getTagsForOpportunity(EventAccessModel item) {
    final title = item.title.toLowerCase();
    final organizer = item.organizer?.toLowerCase() ?? '';

    if (organizer.contains('microsoft') || title.contains('microsoft')) {
      return ['Worldwide', 'Volunteer', 'Perks', 'Swags', 'Certificate'];
    } else if (organizer.contains('nasa') || title.contains('nasa')) {
      return ['On-site', 'Paid', 'Stipend'];
    } else if (organizer.contains('postman') || title.contains('postman')) {
      return ['Remote', 'Stipend'];
    } else if (organizer.contains('google') || title.contains('google')) {
      return ['Remote', 'Stipend', 'Certificate'];
    } else if (organizer.contains('mlh') || title.contains('mlh')) {
      return ['Remote', 'Stipend', 'Fellowship'];
    }

    final List<String> tags = [];
    if (item.location != null && item.location!.isNotEmpty) {
      tags.add(item.location!);
    } else {
      tags.add('Remote');
    }

    if (item.requiredAura > 0) {
      tags.add('Aura Required');
    }

    if (item.type.isNotEmpty) {
      tags.add(item.type);
    }

    return tags;
  }

  Widget _buildBrandLogo(String organizer, String? bannerUrl) {
    final name = organizer.toLowerCase();
    
    // Check if the bannerUrl is actually a logo image (e.g. from Unstop)
    final isLogoUrl = _isLogoUrl(bannerUrl);

    if (isLogoUrl) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: bannerUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade50,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.orange.shade50,
              alignment: Alignment.center,
              child: Text(
                organizer.isNotEmpty ? organizer[0].toUpperCase() : 'O',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (name.contains('microsoft')) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(color: const Color(0xFFF25022)), // Red-orange
            Container(color: const Color(0xFF7FBA00)), // Green
            Container(color: const Color(0xFF00A4EF)), // Blue
            Container(color: const Color(0xFFFFB900)), // Yellow
          ],
        ),
      );
    } else if (name.contains('nasa')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0C2340), // NASA Dark Blue
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'NASA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      );
    } else if (name.contains('postman')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFF6C37), // Postman Orange
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.rocket_launch_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    } else if (name.contains('google')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (name.contains('mlh')) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF004851), // MLH Green
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'MLH',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Default letter avatar
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.orange.shade50,
      child: Text(
        organizer.isNotEmpty ? organizer[0].toUpperCase() : 'O',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Shimmer.fromColors(
            baseColor: AppColors.bg2For(context),
            highlightColor: AppColors.bg3For(context),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String message, VoidCallback onAction) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: AppErrorState(
          title: 'Sync failed',
          message: message,
          actionLabel: 'Try Again',
          onAction: onAction,
        ),
      ),
    );
  }

  Widget _buildUpcomingHackathonsSection(BuildContext context, List<EventAccessModel> events, bool isDark) {
    final realHackathons = events.where((e) => e.type.toLowerCase() == 'hackathon').toList();
    final mockHackathons = [
      const _MockHackathon(
        month: 'MAY',
        date: '24',
        title: 'Hack India 2025',
        mode: 'Hybrid',
        bannerUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?w=800&auto=format&fit=crop',
      ),
      const _MockHackathon(
        month: 'MAY',
        date: '30',
        title: 'Build with AI',
        mode: 'Online',
        bannerUrl: 'https://images.unsplash.com/photo-1677442136019-21780efad99a?w=800&auto=format&fit=crop',
      ),
      const _MockHackathon(
        month: 'JUN',
        date: '07',
        title: 'DevBattle 3.0',
        mode: 'Online',
        bannerUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800&auto=format&fit=crop',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Upcoming Hackathons',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textFor(context),
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: realHackathons.isNotEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: mockHackathons.length,
                  itemBuilder: (context, idx) {
                    final mock = mockHackathons[idx];
                    return _buildHackathonCard(context, mock.month, mock.date, mock.title, mock.mode, isDark, mock.bannerUrl, null);
                  },
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHackathonCard(BuildContext context, String month, String date, String title, String mode, bool isDark, String? bannerUrl, EventAccessModel? realHack) {
    final String displayBannerUrl;
    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      displayBannerUrl = bannerUrl;
    } else {
      final hash = title.hashCode.abs();
      final fallbacks = [
        'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1563089145-599997674d42?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop',
      ];
      displayBannerUrl = fallbacks[hash % fallbacks.length];
    }

    final isLogo = _isLogoUrl(displayBannerUrl);

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
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bg2Dark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  if (isLogo) ...[
                    _buildLogoBanner(context, displayBannerUrl, 95, isDark),
                  ] else ...[
                    CachedNetworkImage(
                      imageUrl: displayBannerUrl,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 95,
                        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F5),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildGradientBanner(
                        context: context,
                        title: title,
                        type: 'HACKATHON',
                        height: 95,
                        isDark: isDark,
                      ),
                    ),
                  ],
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                          height: 1.25,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              mode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text3For(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
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
      int monthIndex = months.indexOf(partLower.length >= 3 ? partLower.substring(0, 3) : partLower);
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

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
        child: AppEmptyState(
          icon: Icons.explore_outlined,
          title: 'No opportunities found',
          message: _searchQuery.isNotEmpty
              ? 'Try searching for something else'
              : 'Check back later for new openings',
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatefulWidget {
  final EventAccessModel item;
  final int myAura;
  final List<String> tags;
  final Widget brandLogo;

  const _OpportunityCard({
    required this.item,
    required this.myAura,
    required this.tags,
    required this.brandLogo,
  });

  @override
  State<_OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<_OpportunityCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = widget.item.requiredAura > widget.myAura;
    final bannerUrl = widget.item.bannerUrl;
    final isLogoUrl = _isLogoUrl(bannerUrl);
    final hasBanner = bannerUrl != null && bannerUrl.trim().isNotEmpty && !isLogoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLocked 
              ? (isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200)
              : AppColors.borderFor(context).withValues(alpha: 0.8),
          width: isLocked ? 1.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OpportunityDetailScreen(opportunity: widget.item),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLogoUrl) ...[
                  Stack(
                    children: [
                      _buildLogoBanner(context, bannerUrl!, 120, isDark),
                      // Type overlay badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.type.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: Color(0xFFFFD60A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else if (hasBanner) ...[
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: bannerUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 150,
                          color: isDark ? AppColors.bg3Dark : const Color(0xFFF1F3F5),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildGradientBanner(
                          context: context,
                          title: widget.item.title,
                          type: widget.item.type,
                          height: 150,
                          isDark: isDark,
                        ),
                      ),
                      // Top gradient overlay for text readability
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Type overlay badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.type.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: Color(0xFFFFD60A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  // If there is no banner, show a beautiful dynamic tech gradient banner
                  Stack(
                    children: [
                      _buildGradientBanner(
                        context: context,
                        title: widget.item.title,
                        type: widget.item.type,
                        height: 120,
                        isDark: isDark,
                      ),
                      // Type overlay badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item.type.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      if (isLocked)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              size: 16,
                              color: Color(0xFFFFD60A),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Organizer & Logo & Bookmark
                      Row(
                        children: [
                          widget.brandLogo,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.organizer ?? 'Opportunity',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text3For(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!hasBanner) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.type.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _isSaved = !_isSaved;
                              });
                            },
                            icon: Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _isSaved
                                  ? AppColors.primary
                                  : AppColors.text3For(context),
                              size: 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Opportunity Title
                      Text(
                        widget.item.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                          color: isLocked
                              ? AppColors.text3For(context)
                              : AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description snippet
                      if (widget.item.description.isNotEmpty) ...[
                        Text(
                          widget.item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.text2For(context),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tags wrap
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.tags
                            .map((tag) => _buildTag(context, tag))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      const Divider(height: 1, thickness: 0.8),
                      const SizedBox(height: 16),

                      // Footer: Close Date & Aura Requirement
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: AppColors.text3For(context),
                                ),
                                const SizedBox(width: 6),
                                Expanded(child: _buildCloseDateText(context, widget.item.date)),
                              ],
                            ),
                          ),
                          if (widget.item.requiredAura > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isLocked 
                                    ? AppColors.bg3For(context)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '⚡',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLocked ? Colors.grey : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.item.requiredAura} Aura',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: isLocked 
                                          ? AppColors.text3For(context)
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // Lock progress if locked
                      if (isLocked) ...[
                        const SizedBox(height: 16),
                        _buildLockProgress(context),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.text2Dark : const Color(0xFF495057),
        ),
      ),
    );
  }

  Widget _buildCloseDateText(BuildContext context, String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return Text(
        'Applications close soon',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.text3For(context),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final lower = dateStr.toLowerCase();
    if (lower.contains('close in') || lower.contains('closes in')) {
      final match = RegExp(r'(\d+\s+days?)').firstMatch(lower);
      if (match != null) {
        final daysText = match.group(1)!;
        final parts = dateStr.split(daysText);
        return RichText(
          text: TextSpan(
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.text3For(context),
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: daysText,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (parts.length > 1) TextSpan(text: parts[1]),
            ],
          ),
        );
      }
    }

    final daysOnly = int.tryParse(dateStr);
    if (daysOnly != null) {
      return RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.text3For(context),
            fontWeight: FontWeight.w500,
          ),
          children: [
            const TextSpan(text: 'Applications close in '),
            TextSpan(
              text: '$daysOnly days',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.text3For(context),
          fontWeight: FontWeight.w500,
        ),
        children: [
          const TextSpan(text: 'Applications close in '),
          TextSpan(
            text: dateStr,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockProgress(BuildContext context) {
    final progress = (widget.myAura / widget.item.requiredAura).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bg3For(context),
            color: AppColors.primary.withValues(alpha: 0.6),
            minHeight: 5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep building your aura to unlock access (${widget.myAura}/${widget.item.requiredAura} Aura)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.text4For(context),
          ),
        ),
      ],
    );
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

class TechPatternPainter extends CustomPainter {
  final Color color;
  TechPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 12.0;
    for (double x = 0.0; x < size.width; x += spacing) {
      for (double y = 0.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TechPatternPainter oldDelegate) => false;
}

Widget _buildGradientBanner({
  required BuildContext context,
  required String title,
  required String type,
  required double height,
  required bool isDark,
}) {
  final hash = title.hashCode.abs();
  final gradients = [
    [const Color(0xFF6366F1), const Color(0xFFA855F7)], // Indigo to Purple
    [const Color(0xFFEC4899), const Color(0xFF8B5CF6)], // Pink to Violet
    [const Color(0xFF3B82F6), const Color(0xFF2DD4BF)], // Blue to Teal
    [const Color(0xFFF43F5E), const Color(0xFFFB7185)], // Rose
    [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
    [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
  ];
  final selectedGradient = gradients[hash % gradients.length];
  final overlayColor = Colors.white.withValues(alpha: 0.08);

  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: selectedGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: TechPatternPainter(color: overlayColor),
          ),
        ),
        Positioned(
          right: -30,
          top: -30,
          child: Container(
            width: height * 1.2,
            height: height * 1.2,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
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

Widget _buildLogoBanner(BuildContext context, String logoUrl, double height, bool isDark) {
  return Container(
    height: height,
    width: double.infinity,
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
          padding: const EdgeInsets.all(12.0),
          child: CachedNetworkImage(
            imageUrl: logoUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.image_outlined,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    ),
  );
}

