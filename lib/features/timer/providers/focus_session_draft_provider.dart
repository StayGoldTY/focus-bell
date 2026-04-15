import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_session_draft.dart';

final focusSessionDraftProvider =
    StateNotifierProvider<FocusSessionDraftNotifier, FocusSessionDraft>((ref) {
      return FocusSessionDraftNotifier();
    });

class FocusSessionDraftNotifier extends StateNotifier<FocusSessionDraft> {
  FocusSessionDraftNotifier() : super(const FocusSessionDraft());

  void setTitle(String value) {
    final trimmed = value.length > 40 ? value.substring(0, 40) : value;
    state = state.copyWith(title: trimmed);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
  }

  void clear() {
    state = const FocusSessionDraft();
  }
}
