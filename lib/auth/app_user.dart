import 'dart:convert';

import 'access_policy.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.pbId = '',
  });

  final int id;
  final String username;
  final String fullName;
  final String email;
  final AppRole role;
  final String pbId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pbId': pbId,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.name,
  };

  static AppUser? fromJson(Map<String, dynamic> json) {
    final role = roleByName(json['role'] as String?);
    final id = json['id'];
    if (role == null || id is! num) return null;
    return AppUser(
      id: id.toInt(),
      pbId: '${json['pbId'] ?? ''}',
      username: '${json['username'] ?? ''}',
      fullName: '${json['fullName'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: role,
    );
  }

  static AppUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map) return fromJson(Map<String, dynamic>.from(json));
    } catch (_) {}
    return null;
  }
}
