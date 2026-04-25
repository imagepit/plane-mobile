import 'package:plane_mobile/domain/entities/work_item.dart';

class WorkItemMemberModel {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? avatar;

  const WorkItemMemberModel({
    required this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.displayName,
    this.avatar,
  });

  factory WorkItemMemberModel.fromJson(Map<String, dynamic> json) {
    return WorkItemMemberModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  WorkItemMember toEntity() => WorkItemMember(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
        avatar: avatar,
      );
}