import '../utils/parsing.dart';

/// A SneakerBro user.
///
/// The original app authenticated users with Firebase Auth, and each user's
/// collection lived in Cloud Firestore. This model is what the rest of the
/// app reads as "the current user," whether it came from the live backend
/// (originally) or from the local stub (now).
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  /// Two-letter initials for the avatar bubble in the profile sheet.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'createdAt': createdAt?.toIso8601String(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: asString(map['id']),
        name: asString(map['name']),
        email: asString(map['email']),
        createdAt: asDate(map['createdAt']),
      );
}
