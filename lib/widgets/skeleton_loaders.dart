import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E22) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF2C2C32) : Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonLoader(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 120, height: 14),
                  const SizedBox(height: 6),
                  const SkeletonLoader(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonLoader(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          const SkeletonLoader(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 200, height: 16),
          const SizedBox(height: 16),
          const SkeletonLoader(width: double.infinity, height: 180, borderRadius: 16),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonLoader(width: 60, height: 24, borderRadius: 12),
              const SkeletonLoader(width: 60, height: 24, borderRadius: 12),
              const SkeletonLoader(width: 60, height: 24, borderRadius: 12),
              const SkeletonLoader(width: 24, height: 24, borderRadius: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const SkeletonLoader(width: 100, height: 100, borderRadius: 50),
        const SizedBox(height: 16),
        const SkeletonLoader(width: 180, height: 24),
        const SizedBox(height: 8),
        const SkeletonLoader(width: 120, height: 16),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const SkeletonLoader(width: 60, height: 40, borderRadius: 8),
          )),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const SkeletonLoader(width: double.infinity, height: 100, borderRadius: 20),
            )),
          ),
        ),
      ],
    );
  }
}
class QuestionCardSkeleton extends StatelessWidget {
  const QuestionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.bg2For(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 150, height: 18),
          const SizedBox(height: 10),
          const SkeletonLoader(width: double.infinity, height: 14),
          const SizedBox(height: 6),
          const SkeletonLoader(width: 200, height: 14),
          const SizedBox(height: 16),
          Row(
            children: [
              const SkeletonLoader(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 8),
              const SkeletonLoader(width: 80, height: 12),
              const Spacer(),
              const SkeletonLoader(width: 40, height: 24, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}
