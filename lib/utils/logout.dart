import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_storage/get_storage.dart';

Future<bool> clearAllAppData() async {
  try {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final prefsCleared = await prefs.clear(); // returns bool

    // Clear GetStorage
    final storage = GetStorage();
    await storage.initStorage; // make sure it's initialized
    await storage.erase(); // returns void, so assume it worked

    return prefsCleared; // return true if SharedPreferences cleared
  } catch (e) {
    print('Error clearing app data: $e');
    return false;
  }
}
