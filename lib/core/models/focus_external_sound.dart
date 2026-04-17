enum FocusSoundSourceType { builtIn, wikimedia, openverse }

FocusSoundSourceType parseFocusSoundSourceType(String? raw) {
  switch (raw) {
    case 'wikimedia':
      return FocusSoundSourceType.wikimedia;
    case 'openverse':
      return FocusSoundSourceType.openverse;
    default:
      return FocusSoundSourceType.builtIn;
  }
}

class FocusExternalSound {
  final FocusSoundSourceType sourceType;
  final String id;
  final String name;
  final String description;
  final String? streamUrl;
  final String? author;
  final double? durationSeconds;
  final String? apiParam;

  const FocusExternalSound({
    required this.sourceType,
    required this.id,
    required this.name,
    required this.description,
    this.streamUrl,
    this.author,
    this.durationSeconds,
    this.apiParam,
  });

  Map<String, Object?> toJson() {
    return {
      'sourceType': sourceType.name,
      'id': id,
      'name': name,
      'description': description,
      'streamUrl': streamUrl,
      'author': author,
      'durationSeconds': durationSeconds,
      'apiParam': apiParam,
    };
  }

  factory FocusExternalSound.fromJson(Map<String, dynamic> json) {
    return FocusExternalSound(
      sourceType: parseFocusSoundSourceType(json['sourceType'] as String?),
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      streamUrl: json['streamUrl'] as String?,
      author: json['author'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      apiParam: json['apiParam'] as String?,
    );
  }

  FocusExternalSound copyWith({
    FocusSoundSourceType? sourceType,
    String? id,
    String? name,
    String? description,
    String? Function()? streamUrl,
    String? Function()? author,
    double? Function()? durationSeconds,
    String? Function()? apiParam,
  }) {
    return FocusExternalSound(
      sourceType: sourceType ?? this.sourceType,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      streamUrl: streamUrl != null ? streamUrl() : this.streamUrl,
      author: author != null ? author() : this.author,
      durationSeconds: durationSeconds != null
          ? durationSeconds()
          : this.durationSeconds,
      apiParam: apiParam != null ? apiParam() : this.apiParam,
    );
  }
}
