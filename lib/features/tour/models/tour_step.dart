import 'package:flutter/widgets.dart';

/// The sequential steps comprising the first-run tour.
enum TourStep {
  s1Welcome,
  s2Goal,
  s3Play,
  s3bPlayExisting,
  s4Community,
  s5Events,
  s6Ranks,
  s7RewardModal,
}

/// The persistence state of the tour for a specific user.
enum TourStatus {
  notStarted,
  inProgress,
  completed,
  skipped;

  static TourStatus fromString(String? val) {
    switch (val) {
      case 'in_progress':
        return TourStatus.inProgress;
      case 'completed':
        return TourStatus.completed;
      case 'skipped':
        return TourStatus.skipped;
      default:
        return TourStatus.notStarted;
    }
  }

  String toDbString() {
    switch (this) {
      case TourStatus.inProgress:
        return 'in_progress';
      case TourStatus.completed:
        return 'completed';
      case TourStatus.skipped:
        return 'skipped';
      case TourStatus.notStarted:
        return 'not_started';
    }
  }
}

/// Target widgets to which coach mark tooltips and spotlights attach.
enum TourAnchorId {
  auraChip,
  firstTierTile,
  tierList,
  createPostButton,
  eventsTab,
  myRankRow,
  ranksTab,
}

/// In-memory registry associating [TourAnchorId]s with their mounted [GlobalKey]s.
class TourAnchorRegistry extends ChangeNotifier {
  TourAnchorRegistry._();
  static final TourAnchorRegistry instance = TourAnchorRegistry._();

  final Map<TourAnchorId, GlobalKey> _anchors = {};

  void register(TourAnchorId id, GlobalKey key) {
    _anchors[id] = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void unregister(TourAnchorId id, [GlobalKey? key]) {
    if (key == null || _anchors[id] == key) {
      _anchors.remove(id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  GlobalKey? getKey(TourAnchorId id) => _anchors[id];

  Rect? getGlobalRect(TourAnchorId id) {
    final key = _anchors[id];
    final context = key?.currentContext;
    if (context == null || !context.mounted) return null;

    try {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || !renderBox.attached) {
        return null;
      }

      final offset = renderBox.localToGlobal(Offset.zero);
      return offset & renderBox.size;
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _anchors.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }
}
