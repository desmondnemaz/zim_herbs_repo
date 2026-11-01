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
  /// Admins also inherit all moderator privileges
  bool get isModerator => this == UserRole.moderator || this == UserRole.admin;
  bool get isStaff => this == UserRole.admin || this == UserRole.moderator;
  bool get isCustomer => this == UserRole.customer;
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool _isModerator;
  final bool isAdmin;
  final String? avatarUrl;
  final String? username;
  final String? phoneNumber;
  final String primaryRole;
  final bool isPractitioner;
  final bool isSupplier;
  final List<String> healthInterests;
  final String? bio;
  final String? location;
  final bool onboardingCompleted;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    bool isModerator = false,
    this.isAdmin = false,
    this.avatarUrl,
    this.username,
    this.phoneNumber,
    this.primaryRole = 'household',
    this.isPractitioner = false,
    this.isSupplier = false,
    this.healthInterests = const [],
    this.bio,
    this.location,
    this.onboardingCompleted = false,
    this.isActive = true,
  }) : _isModerator = isModerator;

  /// True if the user is a moderator or an administrator (admins inherit all moderation rights).
  bool get isModerator => _isModerator || isAdmin || role == UserRole.admin;

  /// True if the user has moderation privileges (Admins inherit moderation privileges,
  /// but Moderators are below Admins and cannot manage users or system roles).
  bool get canModerate => isAdmin || isModerator || role == UserRole.admin || role == UserRole.moderator;

  /// High-level administration privileges strictly reserved for Administrators.
  bool get canManageUsers => isAdmin || role == UserRole.admin;

  String get displayUsername =>
      username != null && username!.trim().isNotEmpty
          ? username!.trim()
          : (email.isNotEmpty ? email.split('@').first : 'user');

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? isModerator,
    bool? isAdmin,
    String? avatarUrl,
    String? username,
    String? phoneNumber,
    String? primaryRole,
    bool? isPractitioner,
    bool? isSupplier,
    List<String>? healthInterests,
    String? bio,
    String? location,
    bool? onboardingCompleted,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isModerator: isModerator ?? this.isModerator,
      isAdmin: isAdmin ?? this.isAdmin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      primaryRole: primaryRole ?? this.primaryRole,
      isPractitioner: isPractitioner ?? this.isPractitioner,
      isSupplier: isSupplier ?? this.isSupplier,
      healthInterests: healthInterests ?? this.healthInterests,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'full_name': name,
      'email': email,
      'role': role.name,
      'is_moderator': isModerator,
      'is_admin': isAdmin,
      'avatarUrl': avatarUrl,
      'avatar_url': avatarUrl,
      'username': username,
      'phone_number': phoneNumber,
      'primary_role': primaryRole,
      'is_practitioner': isPractitioner,
      'is_supplier': isSupplier,
      'health_interests': healthInterests,
      'bio': bio,
      'location': location,
      'onboarding_completed': onboardingCompleted,
      'is_active': isActive,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final isAdminVal = json['is_admin'] as bool? ?? false;
    final isModeratorVal =
        (json['is_moderator'] as bool? ?? false) || isAdminVal;
    final nameVal =
        json['full_name'] as String? ?? json['name'] as String? ?? '';
    final interestsRaw = json['health_interests'];
    final List<String> interestsList = (interestsRaw is List)
        ? interestsRaw.map((e) => e.toString()).toList()
        : const [];

    return UserModel(
      id: (json['id'] ?? '') as String,
      name: nameVal,
      email: (json['email'] ?? '') as String,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => isAdminVal
            ? UserRole.admin
            : (isModeratorVal ? UserRole.moderator : UserRole.customer),
      ),
      isModerator: isModeratorVal,
      isAdmin: isAdminVal,
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl']) as String?,
      username: json['username'] as String?,
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      primaryRole: (json['primary_role'] as String?) ?? 'household',
      isPractitioner: (json['is_practitioner'] as bool?) ?? false,
      isSupplier: (json['is_supplier'] as bool?) ?? false,
      healthInterests: interestsList,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      onboardingCompleted: (json['onboarding_completed'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}
