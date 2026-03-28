import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/event_access_model.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: const Text('Opportunities'),
      ),
      body: Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.events.isEmpty) {
            return const AppLoadingState(
              title: 'Loading opportunities',
              message: 'Checking what your current aura unlocks.',
            );
          }

          if (provider.error != null && provider.events.isEmpty) {
            return AppErrorState(
              title: 'Could not load opportunities',
              message: provider.error!,
              actionLabel: 'Retry',
              onAction: provider.fetchOverview,
            );
          }

          if (provider.events.isEmpty) {
            return const AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No opportunities yet',
              message: 'Founders have not published opportunities yet.',
            );
          }

          final unlocked = provider.unlockedEvents;
          final locked = provider.lockedEvents;

          return RefreshIndicator.adaptive(
            onRefresh: provider.fetchOverview,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SummaryCard(
                  unlockedCount: unlocked.length,
                  lockedCount: locked.length,
                ),
                const SizedBox(height: 20),
                if (unlocked.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Unlocked',
                    subtitle: 'You can apply right now',
                  ),
                  const SizedBox(height: 10),
                  ...unlocked.map(
                    (event) => _OpportunityCard(event: event),
                  ),
                  const SizedBox(height: 14),
                ],
                if (locked.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Locked',
                    subtitle: 'Earn more aura to unlock',
                  ),
                  const SizedBox(height: 10),
                  ...locked.map(
                    (event) => _OpportunityCard(event: event),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int unlockedCount;
  final int lockedCount;

  const _SummaryCard({
    required this.unlockedCount,
    required this.lockedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'Unlocked',
              value: '$unlockedCount',
              color: Colors.green,
            ),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Locked',
              value: '$lockedCount',
              color: AppColors.text3For(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text3For(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textFor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.text3For(context),
          ),
        ),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final EventAccessModel event;

  const _OpportunityCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                event.unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                size: 18,
                color: event.unlocked ? Colors.green : AppColors.text3For(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.description,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.text2For(context),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${event.type} - needs ${event.requiredAura} aura',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: event.unlocked
                  ? () async {
                      await Clipboard.setData(ClipboardData(text: event.link));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: Text(event.unlocked ? 'Copy link' : 'Locked'),
            ),
          ),
        ],
      ),
    );
  }
}
