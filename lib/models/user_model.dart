class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String avatarUrl;
  final String preferredLanguage;
  final int completedTours;
  final String role; // 'tourist' | 'guide'

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.preferredLanguage = 'Қазақша',
    this.completedTours = 0,
    this.role = 'tourist',
  });

  bool get isGuide => role == 'guide';

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? preferredLanguage,
    int? completedTours,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      completedTours: completedTours ?? this.completedTours,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'preferredLanguage': preferredLanguage,
      'completedTours': completedTours,
      'role': role,
    };
  }

  /// REST API: Convert to JSON map
  Map<String, dynamic> toJson() => toMap();

  /// REST API: Create model from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel.fromMap(json);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
      preferredLanguage: map['preferredLanguage'] as String? ?? 'Қазақша',
      completedTours: map['completedTours'] as int? ?? 0,
      role: map['role'] as String? ?? 'tourist',
    );
  }
}
      fullName: map['fullName'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      avatarUrl: map['avatarUrl'] as String,
      preferredLanguage: (map['preferredLanguage'] as String?) ?? 'Қазақша',
      completedTours: (map['completedTours'] as num?)?.toInt() ?? 0,
    );
  }
}
