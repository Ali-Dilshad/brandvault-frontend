enum AssetType { image, video, logo, document, font }

AssetType assetTypeFromString(String s) =>
    AssetType.values.firstWhere(
            (t) => t.name == s, orElse: () => AssetType.document);

class AssetModel {
  final String id;
  final String name;
  final AssetType type;
  final String url;
  final String? folderId;
  final List<String> tags;
  final String? description;
  final String? usageSuggestion;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AssetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.folderId,
    this.tags = const [],
    this.description,
    this.usageSuggestion,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isTrashed => deletedAt != null;

  bool get hasAiMetadata => tags.isNotEmpty || description != null || usageSuggestion != null;

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
    id: json['id'],
    name: json['name'],
    type: assetTypeFromString(json['type']),
    url: json['url'],
    folderId: json['folderId'],
    tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    description: json['description'],
    usageSuggestion: (json['usageSuggestion'] ?? json['usage_suggestion']) as String?,
    updatedAt: DateTime.parse(json['updatedAt']),
    deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
  );

  AssetModel copyWith({
    String? folderId,
    bool clearFolderId = false,
    List<String>? tags,
    String? description,
    String? usageSuggestion,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      AssetModel(
        id: id,
        name: name,
        type: type,
        url: url,
        folderId: clearFolderId ? null : (folderId ?? this.folderId),
        tags: tags ?? this.tags,
        description: description ?? this.description,
        usageSuggestion: usageSuggestion ?? this.usageSuggestion,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );
}

class AiSuggestion {
  final List<String> tags;
  final String description;
  final String usageSuggestion;

  AiSuggestion({required this.tags, required this.description, required this.usageSuggestion});

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    final description = json['description'];
    final usage = json['usage_suggestion'] ?? json['usageSuggestion'];
    if (tags is! List || description is! String || usage is! String) {
      throw const FormatException('AI suggestion is missing required fields');
    }
    return AiSuggestion(
      tags: tags.map((e) => e.toString()).toList(),
      description: description,
      usageSuggestion: usage,
    );
  }
}
