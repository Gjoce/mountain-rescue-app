class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: (data['email'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      role: (data['role'] ?? 'rescuer').toString(),
      isActive: (data['isActive'] as bool?) ?? true,
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

  UserModel copyWith({
    String? email,
    String? name,
    String? role,
    bool? isActive,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
