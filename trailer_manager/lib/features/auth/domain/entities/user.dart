/// User entity
class User {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String role; // 'admin', 'user', or 'guest'
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isGuest => role == 'guest';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        other.role == role &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode ^ phoneNumber.hashCode ^ role.hashCode ^ createdAt.hashCode;
  }
}
