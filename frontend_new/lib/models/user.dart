// lib/models/user.dart

import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isActive;
  final DateTime? dateJoined;
  final String? profileImageUrl;  // ✅ This field

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.isActive,
    this.dateJoined,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first $last';
    }
    return first.isNotEmpty ? first : (last.isNotEmpty ? last : username);
  }
}