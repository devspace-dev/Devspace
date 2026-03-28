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

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      body: AppGradientBackground(
        child: Column(
          children: [
            _buildTabBar(context),
            Expanded(
              child: Consumer<EngagementProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.events.isEmpty) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }

                  if (provider.error != null && provider.events.isEmpty) {
                    return AppErrorState(
                      title: 'Could not load data',
                      message: provider.error!,
                      actionLabel: 'Retry',
                      onAction: provider.fetchOverview,
                    );
                  }

                  final allEvents = provider.events;
                  final opportunities = allEvents.where((e) => e.requiredAura > 0).toList();
                  final events = allEvents.where((e) => e.requiredAura == 0 || e.type.toLowerCase() == 'event').toList();

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
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: AppColors.textFor(context),
        unselectedLabelColor: AppColors.text3For(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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

    return Container(
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
                  color: opp.unlocked ? Colors.green : AppColors.text3For(context),
                ),
                const SizedBox(width: 8),
                AppBadge(
                  label: opp.type.toUpperCase(),
                  color: opp.unlocked ? AppColors.primary : AppColors.text3For(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              opp.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: opp.unlocked ? AppColors.textFor(context) : AppColors.text3For(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              opp.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: opp.unlocked ? AppColors.text2For(context) : AppColors.text4For(context),
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
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3For(context)),
              ),
            ] else
              AppButton(
                height: 48,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: opp.link));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  }
                },
                child: const Text('Join Now', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
          ],
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(event: event)
            .animate()
            .fadeIn(delay: (index * 100).ms)
            .slideX(begin: 0.1);
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventAccessModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container( // Wrap AppCard with Container to apply margin
      margin: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(
                  label: event.type.toUpperCase(),
                  color: event.type.toLowerCase() == 'hackathon' ? Colors.purple : AppColors.primary,
                ),
                Text(
                  'Coming Soon', // In a real app, use event.date
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text3For(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textFor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text2For(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              height: 44,
              backgroundColor: AppColors.bg3For(context),
              foregroundColor: AppColors.textFor(context),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: event.link));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied')),
                  );
                }
              },
              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
