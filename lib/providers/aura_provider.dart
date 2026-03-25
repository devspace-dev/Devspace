import 'package:flutter/material.dart';
import '../models/badge_model.dart';

class AuraProvider extends ChangeNotifier {
  String? _levelUpMessage;
  String? get levelUpMessage => _levelUpMessage;

  void checkLevelUp(int oldAura, int newAura) {
    final oldBadge = getBadge(oldAura);
    final newBadge = getBadge(newAura);
    if (oldBadge.name != newBadge.name) {
      _levelUpMessage = 'You reached ${newBadge.icon} ${newBadge.name}!';
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        _levelUpMessage = null;
        notifyListeners();
      });
    }
  }

  void clearMessage() {
    _levelUpMessage = null;
    notifyListeners();
  }
}
