import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import 'opportunities_screen.dart';
import 'people_screen.dart';

class ExploreScreen extends StatefulWidget {
  final int initialIndex;
  const ExploreScreen({super.key, this.initialIndex = 0});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Custom sliding segment control for Opportunities, Developers
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bg2Dark : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderFor(context).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.text3For(context),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Opportunities'),
                  Tab(text: 'Developers'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  OpportunitiesScreen(),
                  PeopleScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
