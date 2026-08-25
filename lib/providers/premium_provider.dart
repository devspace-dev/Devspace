import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PremiumProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

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
      final response = await _supabase
          .from('users')
          .select('career_goal, career_goal_selected, is_premium')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _isPremium = response['is_premium'] ?? false;
        _careerGoal = response['career_goal'];
        _careerGoalSelected = response['career_goal_selected'] ?? false;
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
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
      try {
        await _supabase.rpc('activate_user_premium', params: {
          'p_payment_id': paymentId,
          'p_order_id': orderId,
        });
      } catch (rpcError) {
        // Fallback for legacy DB schema before migration
        await _supabase.from('users').update({
          'is_premium': true,
          'career_goal_selected': false,
        }).eq('id', user.id);
      }

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
      await _supabase.from('users').update({
        'career_goal': goalId,
        'career_goal_selected': true,
      }).eq('id', user.id);

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
