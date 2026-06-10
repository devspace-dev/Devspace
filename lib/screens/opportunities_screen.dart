import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

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
              sliverContent = _buildErrorState(context, provider.error!, provider.fetchOverview);
            } else {
              final mergedEvents = _getMergedEvents(provider.events);

              // Filter logic
              final filtered = mergedEvents.where((e) {
                // 1. Search Query Filter
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  final matchesTitle = e.title.toLowerCase().contains(query);
                  final matchesDesc = e.description.toLowerCase().contains(query);
                  final matchesOrg = (e.organizer?.toLowerCase() ?? '').contains(query);
                  if (!matchesTitle && !matchesDesc && !matchesOrg) return false;
                }

                // 2. Category Pill Filter
                if (_selectedCategory == 'All') return true;
                if (_selectedCategory == 'Hackathons') {
                  return e.type.toLowerCase() == 'hackathon';
                }
                if (_selectedCategory == 'Internships') {
                  return e.type.toLowerCase() == 'internship' || e.title.toLowerCase().contains('intern');
                }
                if (_selectedCategory == 'Fellowships') {
                  return e.type.toLowerCase() == 'fellowship' || 
                         e.type.toLowerCase() == 'ambassador' || 
                         e.title.toLowerCase().contains('fellow') || 
                         e.title.toLowerCase().contains('ambassador');
                }
                if (_selectedCategory == 'Scholarships') {
                  return e.type.toLowerCase() == 'scholarship' || e.title.toLowerCase().contains('scholar');
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
                          brandLogo: _buildBrandLogo(item.organizer ?? ''),
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

            return RefreshIndicator.adaptive(
              onRefresh: () => provider.fetchOverview(forceChallengeRefresh: true),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context, canPop)),
                  SliverToBoxAdapter(child: _buildSearchHeader(context)),
                  SliverToBoxAdapter(child: _buildCategorySelector(context)),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
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
                      : (isDark ? AppColors.text2Dark : const Color(0xFF495057)),
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
        description: 'Be a leader in your community, build technical skills, and share technology with peers. As a Student Ambassador, you will get access to Microsoft resources, Azure credits, mentorship from industry experts, and a global network of student leaders. You will host workshops, build communities, and gain hands-on experience with cutting-edge tech.\n\nBenefits include free Microsoft certification exams, exclusive swags, and invitations to regional summits.',
        requiredAura: 0,
        link: 'https://mvp.microsoft.com/studentambassadors',
        type: 'Ambassador',
        unlocked: true,
        locked: false,
        organizer: 'Microsoft',
        location: 'Worldwide',
        date: 'Applications close in 5 days',
        bannerUrl: 'https://images.unsplash.com/photo-1625014020903-e329f58a4990?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'nasa_opp',
        title: 'NASA Internships Fall 2025',
        description: 'NASA Internships are competitive awards to support educational opportunities that provide unique NASA-related research and operational experiences. Interns work under the guidance of NASA mentors on real projects, ranging from aerospace engineering and astrophysics to software development and earth sciences.\n\nThis is an unparalleled opportunity to contribute directly to space exploration missions, learn from world-renowned scientists, and build a stellar network in the space tech industry.',
        requiredAura: 0,
        link: 'https://intern.nasa.gov/',
        type: 'Internship',
        unlocked: true,
        locked: false,
        organizer: 'NASA',
        location: 'On-site',
        date: 'Applications close in 12 days',
        bannerUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'postman_opp',
        title: 'Postman Student Expert Program',
        description: 'Postman Student Experts are student leaders who teach their peers about APIs and Postman. Through this self-paced program, you\'ll learn the essentials of API design, testing, and documentation using Postman.\n\nOnce certified, you\'ll unlock access to exclusive Postman swags, invitations to developer events, and resources to host API workshops on your campus. Boost your developer profile and gain official recognition from Postman.',
        requiredAura: 0,
        link: 'https://www.postman.com/student-program/student-expert/',
        type: 'Program',
        unlocked: true,
        locked: false,
        organizer: 'Postman',
        location: 'Remote',
        date: 'Applications close in 7 days',
        bannerUrl: 'https://images.unsplash.com/photo-1618401471353-b98aedd07871?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'mlh_opp',
        title: 'MLH Fellowship',
        description: 'A remote internship alternative for software developers to build open-source projects. The MLH Fellowship is a 12-week program where students collaborate with maintainers on major open-source projects (like React, Jest, and Dask) used by millions.\n\nYou\'ll receive an educational stipend, participate in daily standups, receive code reviews, and learn from senior engineers. Perfect for building a strong portfolio and starting your career in open source.',
        requiredAura: 0,
        link: 'https://fellowship.mlh.io/',
        type: 'Fellowship',
        unlocked: true,
        locked: false,
        organizer: 'MLH',
        location: 'Remote',
        date: 'Applications close in 15 days',
        bannerUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800&auto=format&fit=crop',
      ),
      const EventAccessModel(
        id: 'gsoc_opp',
        title: 'Google Summer of Code 2025',
        description: 'Google Summer of Code is a global program focused on bringing new contributors into open source software development. GSoC contributors work on a 12+ week programming project with an open source organization under the guidance of mentors.\n\nContributors learn about open source culture, get paid a stipend based on their location, and receive invaluable feedback on their code. It is one of the most prestigious open-source initiatives worldwide.',
        requiredAura: 0,
        link: 'https://summerofcode.withgoogle.com/',
        type: 'Program',
        unlocked: true,
        locked: false,
        organizer: 'Google',
        location: 'Remote',
        date: 'Applications close in 20 days',
        bannerUrl: 'https://images.unsplash.com/photo-1572021335469-31706a17aaef?w=800&auto=format&fit=crop',
      ),
    ];

    final merged = List<EventAccessModel>.from(serverEvents);
    for (final mock in screenshotMocks) {
      if (!merged.any((e) => e.title.toLowerCase() == mock.title.toLowerCase())) {
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

  Widget _buildBrandLogo(String organizer) {
    final name = organizer.toLowerCase();
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

  Widget _buildErrorState(BuildContext context, String message, VoidCallback onAction) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bg2Dark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderFor(context),
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OpportunityDetailScreen(opportunity: widget.item)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand Logo
                  widget.brandLogo,
                  const SizedBox(width: 12),

                  // Title and tags
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isLocked
                                ? AppColors.text3For(context)
                                : AppColors.textFor(context),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tags wrap
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.tags.map((tag) => _buildTag(context, tag)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bookmark icon & lock indicator
                  Column(
                    children: [
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
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (isLocked) ...[
                        const SizedBox(height: 8),
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: AppColors.text3For(context),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Footer close date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCloseDateText(context, widget.item.date),
                  if (widget.item.requiredAura > 0)
                    Text(
                      '⚡ ${widget.item.requiredAura} Aura',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text3For(context),
                      ),
                    ),
                ],
              ),

              // Lock progress if locked
              if (isLocked) ...[
                const SizedBox(height: 12),
                _buildLockProgress(context),
              ],
            ],
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
