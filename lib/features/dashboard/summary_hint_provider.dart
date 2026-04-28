import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/services/preferences_service.dart';

final preferencesServiceProvider = Provider((ref) => PreferencesService());

final summaryHintProvider = StateNotifierProvider<SummaryHintNotifier, bool>((
  ref,
) {
  return SummaryHintNotifier(ref.watch(preferencesServiceProvider));
});

class SummaryHintNotifier extends StateNotifier<bool> {
  final PreferencesService _service;

  SummaryHintNotifier(this._service) : super(false) {
    _loadHintStatus();
  }

  Future<void> _loadHintStatus() async {
    final hasSeen = await _service.hasSeenSummaryHint();
    state = !hasSeen;
  }

  Future<void> dismissHint() async {
    if (state) {
      state = false;
      await _service.setHasSeenSummaryHint();
    }
  }
}
