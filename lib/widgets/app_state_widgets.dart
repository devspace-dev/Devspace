import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLoadingState extends StatelessWidget {
  final String title;
  final String message;

  const AppLoadingState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text3,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Icon(icon, color: AppColors.secondary, size: 36),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text3,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const AppErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text3,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
