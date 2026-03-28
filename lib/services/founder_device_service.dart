import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FounderDeviceService {
  FounderDeviceService._internal();
  static final FounderDeviceService instance = FounderDeviceService._internal();

  static const String _prefsKey = 'founder_device_install_id';
  static const Uuid _uuid = Uuid();

  Future<String> getDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existingId = preferences.getString(_prefsKey)?.trim() ?? '';
    if (existingId.isNotEmpty) {
      return existingId;
    }

    final generatedId = _uuid.v4();
    await preferences.setString(_prefsKey, generatedId);
    return generatedId;
  }
}
