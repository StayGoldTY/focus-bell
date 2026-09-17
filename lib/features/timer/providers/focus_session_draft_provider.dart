import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/storage_service.dart';
import '../models/focus_session_draft.dart';

final focusSessionDraftProvider =
    StateNotifierProvider<FocusSessionDraftNotifier, FocusSessionDraft>((ref) {
      return FocusSessionDraftNotifier(ref.read(storageServiceProvider));
    });

class FocusSessionDraftNotifier extends StateNotifier<FocusSessionDraft> {
  FocusSessionDraftNotifier(this._storage)
    : super(
        FocusSessionDraft(
          title: _storage.lastTaskTitle,
          categoryId: _storage.lastTaskCategoryId.isEmpty
              ? null
              : _storage.lastTaskCategoryId,
        ),
      );

  final StorageService _storage;

  void setTitle(String value) {
    final trimmed = value.length > 40 ? value.substring(0, 40) : value;
    state = state.copyWith(title: trimmed);
    unawaited(_storage.setLastTaskTitle(trimmed));
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
    unawaited(_storage.setLastTaskCategoryId(categoryId));
  }

  void restoreFromStorage() {
    final categoryId = _storage.lastTaskCategoryId;
    state = FocusSessionDraft(
      title: _storage.lastTaskTitle,
      categoryId: categoryId.isEmpty ? null : categoryId,
    );
  }
}
