class User {
  final int? id;
  final String name;
  final String email;
  final String role; // 'student', 'teacher'/'instructor', 'admin'
  final String? phone;
  final String? avatar;
  final String? institution;
  final DateTime? createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.institution,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'student',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      institution: json['institution'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'avatar': avatar,
      'institution': institution,
    };
  }
}
