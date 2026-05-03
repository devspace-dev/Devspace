import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/career_goal.dart';
import '../providers/premium_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_ui_kit.dart';
import 'explore_premium_screen.dart';

class CareerGoalOnboardingScreen extends StatefulWidget {
  final bool isChanging;
  const CareerGoalOnboardingScreen({super.key, required this.isChanging});

  @override
  State<CareerGoalOnboardingScreen> createState() => _CareerGoalOnboardingScreenState();
}

class _CareerGoalOnboardingScreenState extends State<CareerGoalOnboardingScreen> {
  String? _selectedGoalId;

  @override
  void initState() {
    super.initState();
    if (widget.isChanging) {
      _selectedGoalId = context.read<PremiumProvider>().careerGoal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumProvider>();
    final limeGreen = const Color(0xFFB8FF57);
    final selectedBorderColor = const Color(0xFF5B5BD6);

    return Scaffold(
      backgroundColor: AppColors.bgFor(context),
      appBar: AppBar(
        title: Text(widget.isChanging ? 'Change Career Goal' : 'Select Your Goal'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: kCareerGoals.length,
            itemBuilder: (context, index) {
              final goal = kCareerGoals[index];
              final isSelected = _selectedGoalId == goal.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGoalId = goal.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.bg2For(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected ? selectedBorderColor : AppColors.borderFor(context),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: selectedBorderColor.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? selectedBorderColor.withValues(alpha: 0.1) : AppColors.bg3For(context),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                goal.icon,
                                color: isSelected ? selectedBorderColor : AppColors.text2For(context),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textFor(context),
                                    ),
                                  ),
                                  Text(
                                    goal.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.text3For(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, color: selectedBorderColor),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          goal.detailedDescription,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.text2For(context),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: goal.skillTags.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bg3For(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text3For(context),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Sticky Bottom Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.bgFor(context).withValues(alpha: 0),
                    AppColors.bgFor(context),
                  ],
                ),
              ),
              child: SafeArea(
                child: AppButton(
                  onPressed: _selectedGoalId == null || premium.isLoading
                    ? null 
                    : () async {
                        final success = await premium.saveCareerGoal(_selectedGoalId!);
                        if (success && mounted) {
                          if (widget.isChanging) {
                            Navigator.pop(context);
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const ExplorePremiumScreen()),
                            );
                          }
                        }
                      },
                  backgroundColor: limeGreen,
                  foregroundColor: Colors.black,
                  child: premium.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Confirm Goal', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
