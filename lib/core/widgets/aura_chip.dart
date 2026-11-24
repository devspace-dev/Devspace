import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text.dart';

class AuraChip extends StatelessWidget {
  const AuraChip(this.value, {super.key});
  final int value;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value Aura',
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
          decoration: BoxDecoration(
            color: Ds.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Ds.border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Ds.aura,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  size: 14,
                  color: Ds.onAura,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: DsText.number.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      );
}

class StreakChip extends StatelessWidget {
  const StreakChip(this.streak, {super.key});
  final int streak;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$streak day streak',
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 4, 14, 4),
          decoration: BoxDecoration(
            color: Ds.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Ds.border, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Ds.hot,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Ds.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$streak',
                style: DsText.number.copyWith(fontSize: 18, color: Ds.hot),
              ),
            ],
          ),
        ),
      );
}
