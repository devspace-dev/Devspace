import 'package:flutter/material.dart';

class AuraProvider extends ChangeNotifier {
  String? _levelUpMessage;
  String? get levelUpMessage => _levelUpMessage;

  void checkLevelUp(int oldAura, int newAura) {
    // Tier levels removed; keep provider clean and silent
  }

  void clearMessage() {
    _levelUpMessage = null;
    notifyListeners();
  }
}
