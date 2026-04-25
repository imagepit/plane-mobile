class Project {
  final String id;
  final String name;
  final String? description;
  final String? coverImage;
  final String network;
  final String workspace;
  final String? defaultAssignee;
  final int? memberCount;
  final int? stateCount;
  final int? issueCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;
  final bool isMember;
  final String? icon;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.coverImage,
    required this.network,
    required this.workspace,
    this.defaultAssignee,
    this.memberCount,
    this.stateCount,
    this.issueCount,
    this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
    this.isMember = true,
    this.icon,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? network,
    String? workspace,
    String? defaultAssignee,
    int? memberCount,
    int? stateCount,
    int? issueCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isMember,
    String? icon,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      network: network ?? this.network,
      workspace: workspace ?? this.workspace,
      defaultAssignee: defaultAssignee ?? this.defaultAssignee,
      memberCount: memberCount ?? this.memberCount,
      stateCount: stateCount ?? this.stateCount,
      issueCount: issueCount ?? this.issueCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isMember: isMember ?? this.isMember,
      icon: icon ?? this.icon,
    );
  }
}