import 'package:flutter/widgets.dart';
import '../models/tour_step.dart';

/// Lightweight wrapper widget that registers its [GlobalKey] with [TourAnchorRegistry]
/// so coach marks can spotlight and anchor tooltips to it dynamically.
class TourAnchor extends StatefulWidget implements PreferredSizeWidget {
  final TourAnchorId id;
  final Widget child;

  const TourAnchor({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  Size get preferredSize => child is PreferredSizeWidget
      ? (child as PreferredSizeWidget).preferredSize
      : const Size.fromHeight(48);

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TourAnchorRegistry.instance.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      TourAnchorRegistry.instance.unregister(oldWidget.id, _key);
      TourAnchorRegistry.instance.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    TourAnchorRegistry.instance.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}
