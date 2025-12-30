class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;

  // NEW
  final bool isActive;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.photoUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      role: (data['role'] ?? 'rescuer').toString(),
      isActive: data['isActive'] is bool ? data['isActive'] as bool : true,
      photoUrl: data['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'photoUrl': photoUrl,
    };
  }

  AppUser copyWith({
    String? email,
    String? name,
    String? role,
    bool? isActive,
    String? photoUrl,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
