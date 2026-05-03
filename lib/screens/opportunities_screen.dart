import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/event_access_model.dart';
import '../providers/engagement_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';
import '../widgets/app_ui_kit.dart';
import 'opportunity_detail_screen.dart';

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: IconThemeData(color: AppColors.textFor(context)),
              title: Text(
                'Opportunities',
                style: TextStyle(
                  color: AppColors.textFor(context),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
      body: AppGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTabBar(context),
              Expanded(
                child: Consumer<EngagementProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.events.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    }

                    if (provider.error != null && provider.events.isEmpty) {
                      return AppErrorState(
                        title: 'Could not load data',
                        message: provider.error!,
                        actionLabel: 'Retry',
                        onAction: provider.fetchOverview,
                      );
                    }

                    // Add a fallback for unexpected empty states when not loading or in error
                    if (provider.events.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.auto_awesome_rounded,
                        title: 'No opportunities found',
                        message:
                            'We could not find any opportunities or events at this time.',
                      );
                    }

                    final allEvents = provider.events;

                    // Opportunities: aura-locked items that are not hackathons.
                    final opportunities = allEvents
                        .where((e) =>
                            e.requiredAura > 0 &&
                            e.type.toLowerCase() != 'hackathon')
                        .toList();

                    // Events: Exclusive hackathons and general events unlocked by aura points.
                    final events = allEvents
                        .where((e) =>
                            e.type.toLowerCase() == 'hackathon' ||
                            (e.requiredAura == 0 &&
                                e.type.toLowerCase() == 'event'))
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _OpportunitiesList(opportunities: opportunities),
                        _EventsList(events: events),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textFor(context),
        unselectedLabelColor: AppColors.text3For(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: const [
          Tab(text: 'Opportunities'),
          Tab(text: 'Events'),
        ],
      ),
    );
  }
}

class _OpportunitiesList extends StatelessWidget {
  final List<EventAccessModel> opportunities;

  const _OpportunitiesList({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    if (opportunities.isEmpty) {
      return const AppEmptyState(
        icon: Icons.auto_awesome_rounded,
        title: 'No opportunities yet',
        message: 'Grow your aura to see more!',
      );
    }

    final myAura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: opportunities.length,
      itemBuilder: (context, index) {
        final opp = opportunities[index];
        return _OpportunityCard(opp: opp, myAura: myAura)
            .animate()
            .fadeIn(delay: (index * 100).ms)
            .slideY(begin: 0.1);
      },
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final EventAccessModel opp;
  final int myAura;

  const _OpportunityCard({required this.opp, required this.myAura});

  @override
  Widget build(BuildContext context) {
    final auraNeeded = opp.requiredAura - myAura;
    final progress = (myAura / opp.requiredAura).clamp(0.0, 1.0);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpportunityDetailScreen(opportunity: opp),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: AppGlassCard(
          opacity: opp.unlocked ? 0.4 : 0.15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    opp.unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    size: 20,
                    color:
                        opp.unlocked ? Colors.green : AppColors.text3For(context),
                  ),
                  const SizedBox(width: 8),
                  AppBadge(
                    label: opp.type.toUpperCase(),
                    color: opp.unlocked
                        ? AppColors.primary
                        : AppColors.text3For(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                opp.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: opp.unlocked
                      ? AppColors.textFor(context)
                      : AppColors.text3For(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                opp.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: opp.unlocked
                      ? AppColors.text2For(context)
                      : AppColors.text4For(context),
                ),
              ),
              const SizedBox(height: 20),
              if (!opp.unlocked) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bg3For(context),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
                const SizedBox(height: 10),
                Text(
                  'Requires ${opp.requiredAura} Aura · You are $auraNeeded away',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text3For(context)),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DETAILS',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<EventAccessModel> events;

  const _EventsList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const AppEmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No events scheduled',
        message: 'Check back soon for hackathons and meetups!',
      );
    }

    final myAura = context.watch<AuthProvider>().currentUserOrNull?.aura ?? 0;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event, myAura: myAura)
            .animate()
            .fadeIn(delay: (index * 100).ms)
            .slideX(begin: 0.1);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventAccessModel event;
  final int myAura;

  const _EventCard({required this.event, required this.myAura});

  @override
  Widget build(BuildContext context) {
    final isHackathon = event.type.toLowerCase() == 'hackathon';
    final auraNeeded = event.requiredAura - myAura;
    final progress = event.requiredAura > 0
        ? (myAura / event.requiredAura).clamp(0.0, 1.0)
        : 1.0;
    final isLocked = event.requiredAura > myAura;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpportunityDetailScreen(opportunity: event),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: AppGlassCard(
          opacity: isLocked ? 0.15 : 0.4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLocked
                            ? Icons.lock_rounded
                            : (isHackathon
                                ? Icons.terminal_rounded
                                : Icons.event_rounded),
                        size: 20,
                        color: isLocked
                            ? AppColors.text3For(context)
                            : (isHackathon
                                ? Colors.purpleAccent
                                : AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      AppBadge(
                        label: event.type.toUpperCase(),
                        color: isLocked
                            ? AppColors.text3For(context)
                            : (isHackathon ? Colors.purple : AppColors.primary),
                      ),
                    ],
                  ),
                  if (!isLocked && isHackathon)
                    const AppBadge(
                      label: 'EXCLUSIVE',
                      color: Colors.amber,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (isHackathon && event.bannerUrl != null && !isLocked)
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(event.bannerUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLocked
                      ? AppColors.text3For(context)
                      : AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isLocked
                      ? AppColors.text4For(context)
                      : AppColors.text2For(context),
                ),
              ),
              const SizedBox(height: 20),
              if (isLocked) ...[
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bg3For(context),
                  color: isHackathon ? Colors.purpleAccent : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
                const SizedBox(height: 10),
                Text(
                  'Unlock at ${event.requiredAura} Aura · $auraNeeded more to go',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3For(context),
                  ),
                ),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (event.date != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.text3For(context)),
                          const SizedBox(width: 4),
                          Text(
                            event.date!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.text3For(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isHackathon ? Colors.purpleAccent : AppColors.primary).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isHackathon ? Colors.purpleAccent : AppColors.primary).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isHackathon ? 'REGISTER NOW' : 'DETAILS',
                            style: TextStyle(
                              color: isHackathon ? Colors.purpleAccent : AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded, 
                            size: 10, 
                            color: isHackathon ? Colors.purpleAccent : AppColors.primary
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
