import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class FounderAccessDeniedView extends StatelessWidget {
  const FounderAccessDeniedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bg2For(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: AppColors.text3For(context),
              ),
              const SizedBox(height: 14),
              Text(
                'Founder tools are locked on this device',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textFor(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Only allowlisted founder or developer devices can use these controls. Add this device in Supabase before trying again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.text2For(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
