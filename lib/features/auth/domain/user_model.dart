enum UserRole {
  customer,
  moderator,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.customer:
        return 'Customer';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isModerator => this == UserRole.moderator;
  bool get isStaff => this == UserRole.admin || this == UserRole.moderator;
  bool get isCustomer => this == UserRole.customer;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isModerator;
  final bool isAdmin;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isModerator = false,
    this.isAdmin = false,
    this.avatarUrl,
  });

  /// True if the user has moderation privileges (Admins inherit moderation privileges,
  /// but Moderators are below Admins and cannot manage users or system roles).
  bool get canModerate => isAdmin || isModerator || role == UserRole.admin || role == UserRole.moderator;

  /// High-level administration privileges strictly reserved for Administrators.
  bool get canManageUsers => isAdmin || role == UserRole.admin;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isModerator,
    bool? isAdmin,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isModerator: isModerator ?? this.isModerator,
      isAdmin: isAdmin ?? this.isAdmin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'is_moderator': isModerator,
      'is_admin': isAdmin,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final isAdminVal = json['is_admin'] as bool? ?? false;
    final isModeratorVal = json['is_moderator'] as bool? ?? false;

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => isAdminVal
            ? UserRole.admin
            : (isModeratorVal ? UserRole.moderator : UserRole.customer),
      ),
      isModerator: isModeratorVal,
      isAdmin: isAdminVal,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
