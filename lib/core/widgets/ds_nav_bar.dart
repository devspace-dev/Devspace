import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/text.dart';

class DsNavItem extends StatelessWidget {
  const DsNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.dot = false,
  });

  final Widget icon;
  final String label;
  final bool active, dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkResponse(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 68,
            height: 64,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 30,
                        decoration: BoxDecoration(
                          color: active ? Ds.aura : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: IconTheme(
                          data: IconThemeData(
                            size: 22,
                            color: active ? Ds.onAura : Ds.muted,
                          ),
                          child: Center(child: icon),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DsText.caption.copyWith(
                          color: active ? Ds.bone : Ds.muted,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (dot)
                  Positioned(
                    top: 2,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Ds.hot,
                        shape: BoxShape.circle,
                        border: Border.all(color: Ds.navBg, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class DsNavBar extends StatelessWidget {
  const DsNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.playDot = false,
    this.ranksDot = false,
    this.profileAvatarUrl,
    this.profileInitials = 'U',
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool playDot;
  final bool ranksDot;
  final String? profileAvatarUrl;
  final String profileInitials;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Ds.navBg,
        border: Border(
          top: BorderSide(color: Ds.border, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              DsNavItem(
                icon: const Icon(Icons.sports_esports_outlined),
                label: 'Play',
                active: currentIndex == 0,
                dot: playDot,
                onTap: () => onTap(0),
              ),
              DsNavItem(
                icon: const Icon(Icons.route_outlined),
                label: 'Path',
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              DsNavItem(
                icon: const Icon(Icons.emoji_events_outlined),
                label: 'Ranks',
                active: currentIndex == 2,
                dot: ranksDot,
                onTap: () => onTap(2),
              ),
              DsNavItem(
                icon: const Icon(Icons.groups_outlined),
                label: 'Community',
                active: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              DsNavItem(
                icon: _buildProfileIcon(currentIndex == 4),
                label: 'Profile',
                active: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(bool active) {
    if (profileAvatarUrl != null && profileAvatarUrl!.isNotEmpty) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? Ds.onAura : Ds.border,
            width: 1.5,
          ),
          image: DecorationImage(
            image: NetworkImage(profileAvatarUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active ? Ds.onAura : Ds.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? Ds.onAura : Ds.border,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        profileInitials.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: active ? Ds.aura : Ds.bone,
        ),
      ),
    );
  }
}
