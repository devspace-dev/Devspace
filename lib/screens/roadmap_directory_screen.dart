import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/roadmap_directory.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';

/// A searchable directory of roadmap.sh roadmaps. DevSpace links to
/// roadmap.sh's own pages (opened in-app via LaunchMode.inAppWebView)
/// rather than reproducing their content, per roadmap.sh's license.
class RoadmapDirectoryScreen extends StatefulWidget {
  const RoadmapDirectoryScreen({super.key});

  @override
  State<RoadmapDirectoryScreen> createState() => _RoadmapDirectoryScreenState();
}

class _RoadmapDirectoryScreenState extends State<RoadmapDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', ...RoadmapCategory.all];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openRoadmap(RoadmapEntry entry) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(entry.url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
      if (!launched && mounted) {
        _showLaunchError(entry.url);
      }
    } catch (_) {
      if (mounted) _showLaunchError(entry.url);
    }
  }

  void _showLaunchError(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = kRoadmapDirectory.where((entry) {
      final matchesCategory =
          _selectedCategory == 'All' || entry.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          entry.slug.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchField(context),
            _buildCategorySelector(context),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No roadmaps found',
                      message: 'Try a different stack or search term.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildRoadmapTile(context, filtered[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roadmaps',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Curated by roadmap.sh — search a stack to open its guide.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
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

  Widget _buildSearchField(BuildContext context) {
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
            hintText: 'Search a stack, e.g. React, DevOps, SQL...',
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
                : null,
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
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedCategory = cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  fontSize: 12.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoadmapTile(BuildContext context, RoadmapEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRoadmap(entry),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textFor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.category,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.text3For(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  color: AppColors.text4For(context),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
