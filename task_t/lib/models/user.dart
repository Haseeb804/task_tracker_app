import 'package:firebase_auth/firebase_auth.dart' as firebase;

class User {
  final String uid;
  final String? email;
  final String? name;
  final String? role;
  final int? id; // Database ID from backend

  User({
    required this.uid,
    this.email,
    this.name,
    this.role,
    this.id,
  });

  // Factory constructor to create User from JSON (backend response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['firebase_id'] ?? '',
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
    );
  }

  // Convert User to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'firebase_id': uid,
      'id': id,
      'email': email,
      'name': name,
      'role': role,
    };
  }

  // Static method to get ID token from Firebase User
  static Future<String?> getIdToken(firebase.User? user) async {
    return await user?.getIdToken();
  }

  // Copy with method for updating user data
  User copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    int? id,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'User{uid: $uid, email: $email, name: $name, role: $role, id: $id}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          name == other.name &&
          role == other.role &&
          id == other.id;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      id.hashCode;
}