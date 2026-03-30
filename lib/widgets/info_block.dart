import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class InfoBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const InfoBlock({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.text3For(context),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
