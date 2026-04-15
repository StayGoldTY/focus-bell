class FocusSessionDraft {
  final String title;
  final String? categoryId;

  const FocusSessionDraft({this.title = '', this.categoryId});

  String? get normalizedTitle {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  FocusSessionDraft copyWith({String? title, String? Function()? categoryId}) {
    return FocusSessionDraft(
      title: title ?? this.title,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
    );
  }
}
