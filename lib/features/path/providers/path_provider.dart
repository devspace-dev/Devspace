import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/curated_roadmaps.dart';
import '../models/roadmap_model.dart';

typedef UserRoadmapsLoader = Future<List<UserRoadmapSelection>> Function(String userId);
typedef RoadmapProgressLoader = Future<Set<String>> Function(String userId, String roadmapId);
typedef RoadmapActivator = Future<bool> Function({
  required String userId,
  required String roadmapId,
  required RoadmapLevel level,
  required int weeklyHours,
  String? previousActiveRoadmapId,
});
typedef RoadmapSaver = Future<bool> Function({
  required String userId,
  required String roadmapId,
});
typedef NodeCompletionToggler = Future<bool> Function({
  required String userId,
  required String roadmapId,
  required String nodeId,
  required bool completed,
});
typedef SettingsUpdater = Future<bool> Function({
  required String userId,
  required String roadmapId,
  required RoadmapLevel level,
  required int weeklyHours,
});
typedef CurrentUserIdGetter = String? Function();

/// State manager for the DevSpace Path engine.
///
/// Features:
/// - Single active roadmap per user (enforced both locally and in Supabase)
/// - Starting level skipping without writing fake completion records
/// - 60fps optimistic node completion toggling with instant rollback on error
/// - Live finish-date and remaining-hour estimation
/// - Next recommended step discovery
/// - Instant multi-term query filtering across curated roadmaps
class PathProvider extends ChangeNotifier {
  final List<Roadmap> _allRoadmaps;
  final UserRoadmapsLoader _userRoadmapsLoader;
  final RoadmapProgressLoader _roadmapProgressLoader;
  final RoadmapActivator _roadmapActivator;
  final RoadmapSaver _roadmapSaver;
  final NodeCompletionToggler _nodeCompletionToggler;
  final SettingsUpdater _settingsUpdater;
  final CurrentUserIdGetter _currentUserIdGetter;

  UserRoadmapSelection? _activeSelection;
  List<UserRoadmapSelection> _savedSelections = [];
  final Set<String> _completedNodeIds = {};
  final Map<String, Set<String>> _progressCache = {};

  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  PathProvider({
    List<Roadmap>? roadmaps,
    UserRoadmapsLoader? userRoadmapsLoader,
    RoadmapProgressLoader? roadmapProgressLoader,
    RoadmapActivator? roadmapActivator,
    RoadmapSaver? roadmapSaver,
    NodeCompletionToggler? nodeCompletionToggler,
    SettingsUpdater? settingsUpdater,
    CurrentUserIdGetter? currentUserIdGetter,
  })  : _allRoadmaps = roadmaps ?? kCuratedRoadmaps,
        _userRoadmapsLoader = userRoadmapsLoader ?? _defaultUserRoadmapsLoader,
        _roadmapProgressLoader =
            roadmapProgressLoader ?? _defaultRoadmapProgressLoader,
        _roadmapActivator = roadmapActivator ?? _defaultRoadmapActivator,
        _roadmapSaver = roadmapSaver ?? _defaultRoadmapSaver,
        _nodeCompletionToggler =
            nodeCompletionToggler ?? _defaultNodeCompletionToggler,
        _settingsUpdater = settingsUpdater ?? _defaultSettingsUpdater,
        _currentUserIdGetter =
            currentUserIdGetter ?? _defaultCurrentUserIdGetter;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  List<Roadmap> get allRoadmaps => List.unmodifiable(_allRoadmaps);
  UserRoadmapSelection? get activeSelection => _activeSelection;
  List<UserRoadmapSelection> get savedSelections =>
      List.unmodifiable(_savedSelections);
  Set<String> get completedNodeIds => Set.unmodifiable(_completedNodeIds);

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String? get currentUserId => _currentUserIdGetter();

  /// The active [Roadmap] object, if the user has selected one.
  Roadmap? get activeRoadmap {
    if (_activeSelection == null) return null;
    return _allRoadmaps
        .cast<Roadmap?>()
        .firstWhere((r) => r?.id == _activeSelection!.roadmapId, orElse: () => null);
  }

  bool get hasActiveRoadmap => activeRoadmap != null;

  RoadmapLevel get currentLevel =>
      _activeSelection?.level ?? RoadmapLevel.beginner;

  int get currentWeeklyHours => _activeSelection?.weeklyHours ?? 6;

  /// Remaining study hours needed to complete active roadmap.
  int get remainingHours {
    final roadmap = activeRoadmap;
    if (roadmap == null) return 0;
    return roadmap.remainingHours(
      level: currentLevel,
      completedNodeIds: _completedNodeIds,
    );
  }

  /// Estimated completion time in weeks for active roadmap.
  int get estimatedWeeks {
    final roadmap = activeRoadmap;
    if (roadmap == null) return 0;
    return roadmap.estimatedWeeks(
      level: currentLevel,
      weeklyHours: currentWeeklyHours,
      completedNodeIds: _completedNodeIds,
    );
  }

  /// Progress fraction (0.0 to 1.0) taking into account skipped foundation nodes.
  double get progressPercent {
    final roadmap = activeRoadmap;
    if (roadmap == null) return 0.0;
    return roadmap.progressPercent(
      level: currentLevel,
      completedNodeIds: _completedNodeIds,
    );
  }

  int get completedActiveCount {
    final roadmap = activeRoadmap;
    if (roadmap == null) return 0;
    final active = roadmap.activeNodesForLevel(currentLevel);
    return active.where((n) => _completedNodeIds.contains(n.id)).length;
  }

  int get totalActiveCount {
    final roadmap = activeRoadmap;
    if (roadmap == null) return 0;
    return roadmap.activeNodesForLevel(currentLevel).length;
  }

  /// Returns the next uncompleted step in sequential/stage order.
  RoadmapNode? get nextRecommendedStep {
    final roadmap = activeRoadmap;
    if (roadmap == null) return null;
    final activeNodes = roadmap.activeNodesForLevel(currentLevel);
    for (final node in activeNodes) {
      if (!_completedNodeIds.contains(node.id)) {
        return node;
      }
    }
    return null;
  }

  /// Instant search filter across all curated roadmaps.
  List<Roadmap> get filteredRoadmaps {
    if (_searchQuery.trim().isEmpty) return _allRoadmaps;
    return _allRoadmaps.where((r) => r.matchesQuery(_searchQuery)).toList();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Loads the user's active & saved roadmaps along with node progress.
  Future<void> loadUserRoadmaps() async {
    final userId = currentUserId;
    if (userId == null) {
      _activeSelection = null;
      _savedSelections = [];
      _completedNodeIds.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final selections = await _userRoadmapsLoader(userId);
      _activeSelection = selections
          .cast<UserRoadmapSelection?>()
          .firstWhere((s) => s?.status == 'active', orElse: () => null);

      _savedSelections = selections.where((s) => s.status == 'saved').toList();

      if (_activeSelection != null) {
        final roadmapId = _activeSelection!.roadmapId;
        final progress = await _loadRoadmapProgress(userId, roadmapId);
        _completedNodeIds
          ..clear()
          ..addAll(progress);
      } else {
        _completedNodeIds.clear();
      }
    } catch (e) {
      _errorMessage = 'Failed to load your roadmap progress: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets [roadmapId] as active, with starting [level] and [weeklyHours].
  ///
  /// Any previously active roadmap is cleanly transitioned to 'saved'.
  /// Progress on previously completed nodes is preserved.
  Future<bool> selectRoadmap({
    required String roadmapId,
    required RoadmapLevel level,
    required int weeklyHours,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = 'Please sign in to choose a learning roadmap.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final prevActiveId = _activeSelection?.roadmapId;

    try {
      final ok = await _roadmapActivator(
        userId: userId,
        roadmapId: roadmapId,
        level: level,
        weeklyHours: weeklyHours,
        previousActiveRoadmapId: prevActiveId,
      );

      if (!ok) {
        throw Exception('Server rejected roadmap activation.');
      }

      // Update local selections
      final now = DateTime.now();
      final newActive = UserRoadmapSelection(
        id: _activeSelection?.id ?? 'temp_${now.millisecondsSinceEpoch}',
        userId: userId,
        roadmapId: roadmapId,
        status: 'active',
        level: level,
        weeklyHours: weeklyHours,
        startedAt: _activeSelection?.startedAt ?? now,
        updatedAt: now,
      );

      // Demote previous active to saved in local state
      if (_activeSelection != null && _activeSelection!.roadmapId != roadmapId) {
        final demoted = UserRoadmapSelection(
          id: _activeSelection!.id,
          userId: userId,
          roadmapId: _activeSelection!.roadmapId,
          status: 'saved',
          level: _activeSelection!.level,
          weeklyHours: _activeSelection!.weeklyHours,
          startedAt: _activeSelection!.startedAt,
          updatedAt: now,
        );
        _savedSelections = [
          ..._savedSelections.where((s) => s.roadmapId != demoted.roadmapId),
          demoted,
        ];
      }

      // Remove newly active roadmap from saved list if it was previously saved
      _savedSelections =
          _savedSelections.where((s) => s.roadmapId != roadmapId).toList();
      _activeSelection = newActive;

      // Load progress for this roadmap
      final progress = await _loadRoadmapProgress(userId, roadmapId);
      _completedNodeIds
        ..clear()
        ..addAll(progress);

      return true;
    } catch (e) {
      _errorMessage = 'Could not set active roadmap: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Saves [roadmapId] for later without setting it as active.
  Future<bool> saveRoadmap(String roadmapId) async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = 'Please sign in to save roadmaps.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _roadmapSaver(userId: userId, roadmapId: roadmapId);
      if (!ok) throw Exception('Server rejected saving roadmap.');

      final now = DateTime.now();
      final savedItem = UserRoadmapSelection(
        id: 'saved_${now.millisecondsSinceEpoch}',
        userId: userId,
        roadmapId: roadmapId,
        status: 'saved',
        level: RoadmapLevel.beginner,
        weeklyHours: 6,
        startedAt: now,
        updatedAt: now,
      );

      _savedSelections = [
        ..._savedSelections.where((s) => s.roadmapId != roadmapId),
        savedItem,
      ];
      return true;
    } catch (e) {
      _errorMessage = 'Could not save roadmap: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Updates starting level and weekly hours for the active roadmap.
  Future<bool> updateActiveSettings({
    required RoadmapLevel level,
    required int weeklyHours,
  }) async {
    final userId = currentUserId;
    if (userId == null || _activeSelection == null) return false;

    final oldSelection = _activeSelection!;
    _activeSelection = UserRoadmapSelection(
      id: oldSelection.id,
      userId: oldSelection.userId,
      roadmapId: oldSelection.roadmapId,
      status: oldSelection.status,
      level: level,
      weeklyHours: weeklyHours,
      startedAt: oldSelection.startedAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final ok = await _settingsUpdater(
        userId: userId,
        roadmapId: oldSelection.roadmapId,
        level: level,
        weeklyHours: weeklyHours,
      );
      if (!ok) throw Exception('Failed to update settings');
      return true;
    } catch (e) {
      _activeSelection = oldSelection;
      _errorMessage = 'Could not update roadmap settings: $e';
      notifyListeners();
      return false;
    }
  }

  /// Optimistically toggles node completion with automatic rollback on error.
  Future<bool> toggleNodeCompletion({
    required String roadmapId,
    required String nodeId,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      _errorMessage = 'Please sign in to mark progress.';
      notifyListeners();
      return false;
    }

    final wasCompleted = _completedNodeIds.contains(nodeId);
    final willComplete = !wasCompleted;

    // 1. Optimistic local update
    if (willComplete) {
      _completedNodeIds.add(nodeId);
    } else {
      _completedNodeIds.remove(nodeId);
    }
    _progressCache[roadmapId] = Set.from(_completedNodeIds);
    _errorMessage = null;
    notifyListeners();

    // 2. Async persistence
    try {
      final success = await _nodeCompletionToggler(
        userId: userId,
        roadmapId: roadmapId,
        nodeId: nodeId,
        completed: willComplete,
      );
      if (!success) {
        throw Exception('Database rejected progress update.');
      }
      return true;
    } catch (e) {
      // 3. Rollback on failure
      if (wasCompleted) {
        _completedNodeIds.add(nodeId);
      } else {
        _completedNodeIds.remove(nodeId);
      }
      _progressCache[roadmapId] = Set.from(_completedNodeIds);
      _errorMessage = 'Could not sync node completion. Reverted.';
      notifyListeners();
      return false;
    }
  }

  Future<Set<String>> _loadRoadmapProgress(
      String userId, String roadmapId) async {
    if (_progressCache.containsKey(roadmapId)) {
      return _progressCache[roadmapId]!;
    }
    final progress = await _roadmapProgressLoader(userId, roadmapId);
    _progressCache[roadmapId] = progress;
    return progress;
  }

  // ---------------------------------------------------------------------------
  // Default Supabase Implementations
  // ---------------------------------------------------------------------------

  static Future<List<UserRoadmapSelection>> _defaultUserRoadmapsLoader(
      String userId) async {
    final response = await Supabase.instance.client
        .from('user_roadmaps')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) =>
            UserRoadmapSelection.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<Set<String>> _defaultRoadmapProgressLoader(
      String userId, String roadmapId) async {
    final response = await Supabase.instance.client
        .from('user_roadmap_progress')
        .select('node_id')
        .eq('user_id', userId)
        .eq('roadmap_id', roadmapId)
        .eq('status', 'completed');

    return (response as List)
        .map((row) => (row as Map)['node_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  static Future<bool> _defaultRoadmapActivator({
    required String userId,
    required String roadmapId,
    required RoadmapLevel level,
    required int weeklyHours,
    String? previousActiveRoadmapId,
  }) async {
    final client = Supabase.instance.client;

    // Demote any existing active roadmaps to 'saved' to satisfy idx_user_roadmaps_one_active
    await client
        .from('user_roadmaps')
        .update({
          'status': 'saved',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('status', 'active');

    // Upsert target roadmap as active
    await client.from('user_roadmaps').upsert({
      'user_id': userId,
      'roadmap_id': roadmapId,
      'status': 'active',
      'level': level.name,
      'weekly_hours': weeklyHours,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,roadmap_id');

    return true;
  }

  static Future<bool> _defaultRoadmapSaver({
    required String userId,
    required String roadmapId,
  }) async {
    await Supabase.instance.client.from('user_roadmaps').upsert({
      'user_id': userId,
      'roadmap_id': roadmapId,
      'status': 'saved',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,roadmap_id');
    return true;
  }

  static Future<bool> _defaultSettingsUpdater({
    required String userId,
    required String roadmapId,
    required RoadmapLevel level,
    required int weeklyHours,
  }) async {
    await Supabase.instance.client
        .from('user_roadmaps')
        .update({
          'level': level.name,
          'weekly_hours': weeklyHours,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('roadmap_id', roadmapId);
    return true;
  }

  static Future<bool> _defaultNodeCompletionToggler({
    required String userId,
    required String roadmapId,
    required String nodeId,
    required bool completed,
  }) async {
    final client = Supabase.instance.client;
    if (completed) {
      await client.from('user_roadmap_progress').upsert({
        'user_id': userId,
        'roadmap_id': roadmapId,
        'node_id': nodeId,
        'status': 'completed',
        'completed_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,roadmap_id,node_id');
    } else {
      await client
          .from('user_roadmap_progress')
          .delete()
          .eq('user_id', userId)
          .eq('roadmap_id', roadmapId)
          .eq('node_id', nodeId);
    }
    return true;
  }

  static String? _defaultCurrentUserIdGetter() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}
