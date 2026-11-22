import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text.dart';
import '../../../core/widgets/ds_button.dart';
import '../../../core/widgets/ds_card.dart';
import '../../../core/widgets/ds_tag.dart';
import '../../../core/widgets/glitch.dart';
import '../tour_copy.dart';
import 'typewriter_text.dart';

/// Fullscreen modal dialog used for S1 Welcome and S7 Reward Celebration.
class TourModalPopup extends StatelessWidget {
  final String title;
  final String body;
  final GlitchMood mood;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryPressed;
  final Widget? extraContent;

  const TourModalPopup({
    super.key,
    required this.title,
    required this.body,
    this.mood = GlitchMood.hype,
    required this.primaryButtonLabel,
    required this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.onSecondaryPressed,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: DsCard(
        padding: const EdgeInsets.all(22),
        borderColor: Ds.aura,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Single Glitch Mascot
            Glitch(size: 80, mood: mood),
            const SizedBox(height: 16),

            // Title
            Text(
              title.toUpperCase(),
              style: DsText.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Animated / Instant Body Text
            TypewriterText(
              text: body,
              style: DsText.body.copyWith(
                color: Ds.bone,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Optional extra content (e.g. badge reward row for S7)
            if (extraContent != null) ...[
              extraContent!,
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DsButton(
                  label: primaryButtonLabel,
                  kind: DsButtonKind.aura,
                  onPressed: onPrimaryPressed,
                ),
                if (secondaryButtonLabel != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(
                      secondaryButtonLabel!,
                      style: DsText.caption.copyWith(color: Ds.muted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// S2 Goal selection bottom sheet modal.
class TourGoalSheet extends StatefulWidget {
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onSkip;

  const TourGoalSheet({
    super.key,
    required this.onGoalSelected,
    required this.onSkip,
  });

  @override
  State<TourGoalSheet> createState() => _TourGoalSheetState();
}

class _TourGoalSheetState extends State<TourGoalSheet> {
  String _selectedRoadmapId = TourCopy.s2OptionDsaRoadmapId;

  final List<Map<String, String>> _options = const [
    {
      'id': TourCopy.s2OptionDsaRoadmapId,
      'title': TourCopy.s2OptionDsaTitle,
      'desc': TourCopy.s2OptionDsaDesc,
    },
    {
      'id': TourCopy.s2OptionFlutterRoadmapId,
      'title': TourCopy.s2OptionFlutterTitle,
      'desc': TourCopy.s2OptionFlutterDesc,
    },
    {
      'id': TourCopy.s2OptionHackathonRoadmapId,
      'title': TourCopy.s2OptionHackathonTitle,
      'desc': TourCopy.s2OptionHackathonDesc,
    },
    {
      'id': TourCopy.s2OptionWebRoadmapId,
      'title': TourCopy.s2OptionWebTitle,
      'desc': TourCopy.s2OptionWebDesc,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Ds.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: Ds.aura, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Glitch Mascot + Header
              Row(
                children: [
                  const Glitch(size: 48, mood: GlitchMood.idle),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TourCopy.s2GoalTitle.toUpperCase(),
                          style: DsText.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          TourCopy.s2GoalBody,
                          style: DsText.caption.copyWith(color: Ds.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 4 Goal Options
              for (final opt in _options) ...[
                _buildOptionTile(
                  id: opt['id']!,
                  title: opt['title']!,
                  desc: opt['desc']!,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),

              // Confirm Action Button
              DsButton(
                label: TourCopy.s2GoalAction,
                kind: DsButtonKind.aura,
                onPressed: () => widget.onGoalSelected(_selectedRoadmapId),
              ),
              const SizedBox(height: 8),

              // Skip text
              Center(
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    TourCopy.s1WelcomeSkip,
                    style: DsText.caption.copyWith(color: Ds.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String id,
    required String title,
    required String desc,
  }) {
    final isSelected = _selectedRoadmapId == id;

    return InkWell(
      onTap: () => setState(() => _selectedRoadmapId = id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Ds.ink : Ds.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Ds.aura : Ds.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Ds.aura : Ds.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DsText.label.copyWith(
                      color: isSelected ? Ds.aura : Ds.bone,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: DsText.caption.copyWith(color: Ds.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
