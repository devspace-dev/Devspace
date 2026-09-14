import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

class PremiumProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _service = SupabaseService.instance;

  bool _isPremium = false;
  String? _careerGoal;
  bool _careerGoalSelected = false;
  bool _isLoading = false;

  bool get isPremium => _isPremium;
  String? get careerGoal => _careerGoal;
  bool get careerGoalSelected => _careerGoalSelected;
  bool get isLoading => _isLoading;

  PremiumProvider() {
    loadUserPremiumStatus();
  }

  Future<void> loadUserPremiumStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.fetchFullPremiumStatus(user.id);

      if (response != null) {
        _isPremium = response['is_premium'] ?? false;
        _careerGoal = response['career_goal'];
        _careerGoalSelected = response['career_goal_selected'] ?? false;
      }
    } catch (e) {
      try {
        final basicResponse = await _service.fetchBasicPremiumStatus(user.id);
        if (basicResponse != null) {
          _isPremium = basicResponse['is_premium'] ?? false;
        }
      } catch (_) {}
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> activatePremium({String paymentId = '', String orderId = ''}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.activatePremium(
        userId: user.id,
        paymentId: paymentId,
        orderId: orderId,
      );

      _isPremium = true;
      _careerGoalSelected = false;
      return true;
    } catch (e) {
      debugPrint('Error activating premium: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> saveCareerGoal(String goalId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _service.saveCareerGoal(userId: user.id, goalId: goalId);

      _careerGoal = goalId;
      _careerGoalSelected = true;
      return true;
    } catch (e) {
      debugPrint('Error saving career goal: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
