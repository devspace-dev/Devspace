import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/devspace_ui_helper.dart';
import '../models/user_model.dart';
import 'user_avatar.dart';

class ShareableProfileCard extends StatefulWidget {
  final UserModel user;
  final int reposCount;
  final int commitsCount;

  const ShareableProfileCard({
    super.key,
    required this.user,
    this.reposCount = 0,
    this.commitsCount = 0,
  });

  @override
  State<ShareableProfileCard> createState() => _ShareableProfileCardState();
}

class _ShareableProfileCardState extends State<ShareableProfileCard> {
  final GlobalKey _boundaryKey = GlobalKey();

  Future<void> _shareImage() async {
    try {
      RenderRepaintBoundary? boundary = 
          _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/devspace_profile.png').create();
      await imagePath.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Check out my builder profile on DevSpace! 🚀',
      );
    } catch (e) {
      debugPrint('Error sharing profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = TierHelper.getTier(widget.user.aura);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: Container(
            width: 320,
            height: 180,
            decoration: BoxDecoration(
              color: DevSpaceColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              children: [
                // Subtle Radial Gradient
                Positioned(
                  top: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tier.accentColor.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Top Row: Avatar & Identity
                      Row(
                        children: [
                          UserAvatar(user: widget.user, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.user.name,
                                      style: DevSpaceColors.headingStyle(
                                        fontSize: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (widget.user.aura >= 5000) // Verification threshold
                                      const Padding(
                                        padding: EdgeInsets.only(left: 6),
                                        child: Icon(Icons.verified, color: DevSpaceColors.primary, size: 16),
                                      ),
                                  ],
                                ),
                                Text(
                                  '@${widget.user.handle}',
                                  style: const TextStyle(color: DevSpaceColors.gray, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Middle Row: Tier Badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: tier.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: tier.accentColor.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(tier.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                tier.name.toUpperCase(),
                                style: DevSpaceColors.headingStyle(
                                  fontSize: 15,
                                  color: tier.accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Bottom Row: Stats & Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              _StatChip(label: 'REPOS', value: widget.reposCount.toString()),
                              const SizedBox(width: 12),
                              _StatChip(label: 'COMMITS', value: widget.commitsCount.toString()),
                              const SizedBox(width: 12),
                              _StatChip(label: 'AURA', value: widget.user.aura.toString()),
                            ],
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'DevSpace',
                                style: DevSpaceColors.headingStyle(
                                  fontSize: 12,
                                  color: DevSpaceColors.primary,
                                ),
                              ),
                              const Text(
                                'BUILDER CARD',
                                style: TextStyle(color: DevSpaceColors.gray, fontSize: 8, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        ElevatedButton.icon(
          onPressed: _shareImage,
          icon: const Icon(Icons.share_rounded, size: 18),
          label: const Text('SHARE PROFILE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DevSpaceColors.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: DevSpaceColors.gray, fontSize: 8, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
