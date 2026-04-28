import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _summaryHintKey = 'has_seen_summary_hint';

  Future<void> setHasSeenSummaryHint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_summaryHintKey, true);
  }

  Future<bool> hasSeenSummaryHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_summaryHintKey) ?? false;
  }
}
