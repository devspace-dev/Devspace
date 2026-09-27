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
import '../utils/hackathon_region.dart';
import '../utils/opportunity_banner.dart';
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
            // India-only: hide legacy international (Devpost) hackathon rows.
            final events =
                provider.events.where((e) => !isNonIndianHackathon(e)).toList();
            int? resultCount;
            Widget sliverContent;

            if (provider.isLoading && provider.events.isEmpty) {
              sliverContent = _buildLoadingSkeleton();
            } else if (provider.error != null && provider.events.isEmpty) {
              sliverContent = _buildErrorState(
                  context, provider.error!, provider.fetchOverview);
            } else {
              final mergedEvents = events;

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
                  if (!matchesTitle && !matchesDesc && !matchesOrg) {
                    return false;
                  }
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

              resultCount = filtered.length;
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
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  if (_searchQuery.isEmpty && (_selectedCategory == 'All' || _selectedCategory == 'Hackathons'))
                    SliverToBoxAdapter(child: _buildUpcomingHackathonsSection(context, events, isDark)),
                  if (resultCount != null)
                    SliverToBoxAdapter(
                      child: _buildResultCount(context, resultCount),
                    ),
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
                  color: AppColors.bg3For(context),
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
                  'Explore Opportunities',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.9),
          ),
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
                color: isSelected ? AppColors.primary : AppColors.bg3For(context),
                borderRadius: BorderRadius.circular(100),
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : AppColors.text2For(context),
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

    // Default monogram avatar (colour picked from the shared palette by name).
    final avatarColor = _bannerPalette[organizer.hashCode.abs() % _bannerPalette.length];
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: avatarColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _monogram(organizer.isNotEmpty ? organizer : 'O'),
        style: GoogleFonts.plusJakartaSans(
          color: avatarColor,
          fontWeight: FontWeight.w800,
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

  bool _isPastEvent(EventAccessModel e) {
    final end = DateTime.tryParse(e.endDate ?? '') ?? DateTime.tryParse(e.date ?? '');
    if (end == null) return false;
    final now = DateTime.now();
    return end.isBefore(DateTime(now.year, now.month, now.day));
  }

  Widget _buildUpcomingHackathonsSection(BuildContext context, List<EventAccessModel> events, bool isDark) {
    final upcoming = events
        .where((e) => e.type.toLowerCase() == 'hackathon' && !_isPastEvent(e))
        .toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
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
              if (_selectedCategory != 'Hackathons')
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCategory = 'Hackathons');
                  },
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: upcoming.length,
            itemBuilder: (context, idx) {
              final hack = upcoming[idx];
              final parsedDate = _parseHackathonDate(hack.date, hack.endDate);
              return _buildHackathonCard(
                context,
                parsedDate?['month'] ?? 'TBA',
                parsedDate?['day'] ?? '--',
                hack.title,
                hack.location ?? 'Online',
                isDark,
                hack.bannerUrl,
                hack,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHackathonCard(BuildContext context, String month, String date, String title, String mode, bool isDark, String? bannerUrl, EventAccessModel? realHack) {
    const double bannerHeight = 92;
    final isLogo = _isLogoUrl(bannerUrl);
    final hasPhoto = bannerUrl != null &&
        bannerUrl.isNotEmpty &&
        !isLogo &&
        !isPlaceholderPhotoUrl(bannerUrl);

    Widget flatBanner() => _buildFlatBanner(
          seed: title,
          label: title,
          height: bannerHeight,
        );

    final Widget banner;
    if (isLogo) {
      banner = _buildLogoBanner(context, bannerUrl!, bannerHeight, isDark);
    } else if (hasPhoto) {
      banner = CachedNetworkImage(
        imageUrl: bannerUrl,
        height: bannerHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: bannerHeight,
          color: AppColors.bg3For(context),
        ),
        errorWidget: (context, url, error) => flatBanner(),
      );
    } else {
      banner = flatBanner();
    }

    final modeLower = mode.toLowerCase();
    final isOnline = modeLower.contains('online') || modeLower.contains('remote');

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
        width: 190,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.bg2For(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderFor(context).withValues(alpha: 0.9),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  banner,
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            month,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            date,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF16151A),
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
                        children: [
                          Icon(
                            isOnline
                                ? Icons.language_rounded
                                : Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.text3For(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              mode,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
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

  // Returns the real month/day for a hackathon, or null when the date can't be
  // read (the card then shows "TBA" instead of an invented date).
  Map<String, String>? _parseHackathonDate(String? dateStr, [String? endDateStr]) {
    String? raw = dateStr?.trim();
    if ((raw == null || raw.isEmpty) && endDateStr != null && endDateStr.trim().isNotEmpty) {
      raw = endDateStr.trim();
    }
    if (raw == null || raw.isEmpty) return null;

    final parsedDate = DateTime.tryParse(raw);
    if (parsedDate != null) {
      return {
        'month': _getMonthAbbreviation(parsedDate.month),
        'day': parsedDate.day.toString(),
      };
    }

    final cleaned = raw.replaceAll(RegExp(r'[,:\-\/]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
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

    if (foundMonth == null && endDateStr != null && endDateStr.trim().isNotEmpty && endDateStr != raw) {
      final parsedEnd = DateTime.tryParse(endDateStr.trim());
      if (parsedEnd != null) {
        return {
          'month': _getMonthAbbreviation(parsedEnd.month),
          'day': parsedEnd.day.toString(),
        };
      }
    }

    if (foundMonth == null) return null;
    if (foundDay == null) {
      for (final part in parts) {
        if (RegExp(r'^\d+$').hasMatch(part)) {
          foundDay = part;
          break;
        }
      }
    }
    if (foundDay == null) return null;
    return {'month': foundMonth, 'day': foundDay};
  }

  String _getMonthAbbreviation(int monthIndex) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    if (monthIndex >= 1 && monthIndex <= 12) {
      return months[monthIndex - 1];
    }
    return 'MAY';
  }

  Widget _buildResultCount(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Text(
        count == 1 ? '1 opportunity' : '$count opportunities',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.text3For(context),
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
  final Widget brandLogo;

  const _OpportunityCard({
    required this.item,
    required this.myAura,
    required this.brandLogo,
  });

  @override
  State<_OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<_OpportunityCard> {
  bool _isSaved = false;

  static const double _photoHeight = 120;

  // A real event image (not a logo, not a stock placeholder), if there is one.
  String? get _photoUrl {
    final url = widget.item.bannerUrl;
    if (url == null || url.trim().isEmpty) return null;
    if (_isLogoUrl(url) || isPlaceholderPhotoUrl(url)) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLocked = item.requiredAura > widget.myAura;
    final photoUrl = _photoUrl;
    final location = item.location?.trim() ?? '';
    final typeLabel = item.type.isEmpty
        ? 'Opportunity'
        : item.type[0].toUpperCase() + item.type.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderFor(context)
              .withValues(alpha: isLocked ? 0.5 : 0.9),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OpportunityDetailScreen(opportunity: item),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrl != null) _buildPhoto(photoUrl),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + title/organizer + bookmark
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          widget.brandLogo,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: isLocked
                                        ? AppColors.text3For(context)
                                        : AppColors.textFor(context),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.organizer ?? 'Opportunity',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text3For(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() => _isSaved = !_isSaved);
                            },
                            child: Icon(
                              _isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: _isSaved
                                  ? AppColors.primary
                                  : AppColors.text3For(context),
                              size: 22,
                            ),
                          ),
                        ],
                      ),

                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.text2For(context),
                            height: 1.45,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildMetaChip(
                            context,
                            icon: Icons.local_offer_outlined,
                            label: typeLabel,
                            color: _typeColor(item.type),
                            tinted: true,
                          ),
                          if (location.isNotEmpty)
                            _buildMetaChip(
                              context,
                              icon: location.toLowerCase().contains('online')
                                  ? Icons.language_rounded
                                  : Icons.location_on_outlined,
                              label: location,
                            ),
                          if (item.requiredAura > 0)
                            _buildMetaChip(
                              context,
                              icon: isLocked
                                  ? Icons.lock_rounded
                                  : Icons.bolt_rounded,
                              label: '${item.requiredAura} Aura',
                              color: isLocked
                                  ? AppColors.text3For(context)
                                  : AppColors.primary,
                              tinted: !isLocked,
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: AppColors.borderFor(context).withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),

                      // Deadline
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: AppColors.text3For(context),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildCloseDateText(
                                context, item.date, item.endDate),
                          ),
                        ],
                      ),

                      if (isLocked) ...[
                        const SizedBox(height: 14),
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

  Widget _buildPhoto(String url) {
    Widget fallback() => _buildFlatBanner(
          seed: widget.item.title,
          label: widget.item.organizer ?? widget.item.title,
          height: _photoHeight,
        );

    return CachedNetworkImage(
      imageUrl: url,
      height: _photoHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        height: _photoHeight,
        color: AppColors.bg3For(context),
      ),
      errorWidget: (context, _, __) => fallback(),
    );
  }

  Widget _buildMetaChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
    bool tinted = false,
  }) {
    final fg = color ?? AppColors.text2For(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tinted ? fg.withValues(alpha: 0.12) : AppColors.bg3For(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseDateText(BuildContext context, String? dateStr, [String? endDateStr]) {
    final lowerDate = (dateStr ?? '').trim().toLowerCase();

    // 1. If endDate is available, calculate precise countdown
    if (endDateStr != null && endDateStr.trim().isNotEmpty) {
      final parsedEnd = DateTime.tryParse(endDateStr.trim());
      if (parsedEnd != null) {
        final diff = parsedEnd.difference(DateTime.now());
        if (diff.isNegative) {
          return Text(
            'Event concluded',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.text3For(context),
              fontWeight: FontWeight.w500,
            ),
          );
        } else if (diff.inDays > 0) {
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
                  text: '${diff.inDays} ${diff.inDays == 1 ? "day" : "days"}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        } else if (diff.inHours > 0) {
          return RichText(
            text: TextSpan(
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.text3For(context),
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'Closes in '),
                TextSpan(
                  text: '${diff.inHours} hours',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }
      }
    }

    if (dateStr == null || dateStr.trim().isEmpty) {
      return Text(
        'Applications close soon',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.text3For(context),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (lowerDate.contains('close in') || lowerDate.contains('closes in')) {
      final match = RegExp(r'(\d+\s+days?)').firstMatch(lowerDate);
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

    final daysOnly = int.tryParse(dateStr.trim());
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

    final prefix = lowerDate.startsWith('closes') ? '' : 'Date: ';
    return RichText(
      text: TextSpan(
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.text3For(context),
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(
            text: dateStr.trim(),
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

// Flat banner used whenever an opportunity has no usable image. The colour is
// picked from a small palette by seed, so a given item always looks the same.
const _bannerPalette = [
  Color(0xFFFF7A33), // ember orange
  Color(0xFF3F63E8), // blue
  Color(0xFF2FA85C), // green
  Color(0xFFE5484D), // coral
  Color(0xFF0E9AA7), // teal
  Color(0xFF64748B), // slate
];

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'hackathon':
      return const Color(0xFFFF7A33);
    case 'internship':
      return const Color(0xFF3F63E8);
    case 'scholarship':
      return const Color(0xFF2FA85C);
    case 'fellowship':
    case 'ambassador':
    case 'program':
      return const Color(0xFF0E9AA7);
    default:
      return const Color(0xFF6B7280);
  }
}

String _monogram(String text) {
  final match = RegExp(r'[A-Za-z0-9]').firstMatch(text);
  return match != null ? match.group(0)!.toUpperCase() : '#';
}

Widget _bannerCircle(double size, double alpha) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );
}

Widget _buildFlatBanner({
  required String seed,
  required String label,
  required double height,
}) {
  final color = _bannerPalette[seed.hashCode.abs() % _bannerPalette.length];

  return Container(
    height: height,
    width: double.infinity,
    color: color,
    child: Stack(
      children: [
        Positioned(
          right: -28,
          top: -28,
          child: _bannerCircle(height * 1.1, 0.10),
        ),
        Positioned(
          left: -24,
          bottom: -40,
          child: _bannerCircle(height * 0.75, 0.08),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              _monogram(label.isNotEmpty ? label : seed),
              style: GoogleFonts.plusJakartaSans(
                fontSize: height * 0.5,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: Colors.white.withValues(alpha: 0.9),
              ),
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

