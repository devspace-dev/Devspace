import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/engagement_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_state_widgets.dart';

class AuraHistoryScreen extends StatefulWidget {
  const AuraHistoryScreen({super.key});

  @override
  State<AuraHistoryScreen> createState() => _AuraHistoryScreenState();
}

class _AuraHistoryScreenState extends State<AuraHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EngagementProvider>().fetchAuraHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        backgroundColor: AppColors.bgFor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textFor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aura History',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textFor(context),
          ),
        ),
      ),
      body: Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingHistory && provider.auraHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (provider.error != null && provider.auraHistory.isEmpty) {
            return AppErrorState(
              title: 'Failed to load history',
              message: provider.error!,
              actionLabel: 'Retry',
              onAction: provider.fetchAuraHistory,
            );
          }

          if (provider.auraHistory.isEmpty) {
            return AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No aura history yet',
              message: 'Start interacting with the community to earn aura!',
              actionLabel: 'Go Home',
              onAction: () => Navigator.pop(context),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.fetchAuraHistory,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: provider.auraHistory.length,
              itemBuilder: (context, index) {
                final item = provider.auraHistory[index];
                final isPositive = item.points >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bg2For(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderFor(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isPositive ? AppColors.primary : AppColors.like).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                          color: isPositive ? AppColors.primary : AppColors.like,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.textFor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.text3For(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${item.points}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: isPositive ? AppColors.primary : AppColors.like,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
