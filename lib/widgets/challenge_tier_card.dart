import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_ui_kit.dart';

class ChallengeTierCard extends StatelessWidget {
  final String title;
  final String description;
  final String? price;
  final List<String> features;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isPremium;
  final IconData icon;
  final Color accentColor;
  final bool isEnrolled;
  final bool isLoading;

  const ChallengeTierCard({
    super.key,
    required this.title,
    required this.description,
    this.price,
    required this.features,
    required this.buttonText,
    required this.onPressed,
    this.isPremium = false,
    required this.icon,
    required this.accentColor,
    this.isEnrolled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    
    return AppCard(
      padding: EdgeInsets.zero,
      color: isPremium 
          ? accentColor.withValues(alpha: isDark ? 0.1 : 0.05) 
          : AppColors.bg2For(context),
      border: Border.all(
        color: isPremium 
            ? accentColor.withValues(alpha: 0.3) 
            : AppColors.borderFor(context),
        width: isPremium ? 2 : 1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Gradient for Premium
          Container(
            padding: const EdgeInsets.all(20),
            decoration: isPremium ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.2),
                  accentColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ) : null,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textFor(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPremium) ...[
                            const SizedBox(width: 8),
                            AppBadge(
                              label: 'PRO',
                              color: accentColor,
                              icon: Icons.auto_awesome,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price ?? 'FREE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isPremium ? accentColor : AppColors.text3For(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.text2For(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Features List
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: isPremium ? accentColor : Colors.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textFor(context),
                            fontWeight: isPremium && (feature.contains('Roadmap') || feature.contains('Career'))
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                
                const SizedBox(height: 24),
                
                if (isEnrolled)
                  AppButton(
                    onPressed: onPressed,
                    backgroundColor: Colors.green,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isPremium ? 'Premium Active' : 'Active',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  )
                else
                  AppButton(
                    onPressed: isLoading ? null : onPressed,
                    backgroundColor: isPremium ? accentColor : AppColors.textFor(context),
                    foregroundColor: isPremium ? Colors.white : AppColors.bgFor(context),
                    isLoading: isLoading,
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
