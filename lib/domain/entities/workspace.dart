class Workspace {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final int? memberCount;
  final int? projectCount;

  const Workspace({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    this.memberCount,
    this.projectCount,
  });

  Workspace copyWith({
    String? id,
    String? name,
    String? slug,
    String? logo,
    int? memberCount,
    int? projectCount,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logo: logo ?? this.logo,
      memberCount: memberCount ?? this.memberCount,
      projectCount: projectCount ?? this.projectCount,
    );
  }
}