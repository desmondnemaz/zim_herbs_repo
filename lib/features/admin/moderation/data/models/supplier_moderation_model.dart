/// Model representing a botanical supplier profile for moderation and publishing
class SupplierModerationModel {
  final String id; // References user_profiles.id
  final String supplierName;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? location;
  final String? bio;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final DateTime? createdAt;

  const SupplierModerationModel({
    required this.id,
    required this.supplierName,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    this.location,
    this.bio,
    required this.verificationStatus,
    this.createdAt,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isPending =>
      verificationStatus.toLowerCase() == 'pending' ||
      verificationStatus.trim().isEmpty;
  bool get isRejected => verificationStatus.toLowerCase() == 'rejected';

  factory SupplierModerationModel.fromJson(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;

    final userFullName = userProfile?['full_name'] as String? ??
        (userProfile?['username'] as String?);
    final userEmail = userProfile?['email'] as String? ?? '';
    final userPhone = userProfile?['phone_number'] as String?;
    final userAvatar = userProfile?['avatar_url'] as String?;
    final userBio = userProfile?['bio'] as String?;

    return SupplierModerationModel(
      id: json['id'] as String,
      supplierName:
          (json['supplier_name'] as String?)?.trim() ?? 'Botanical Supplier',
      fullName: (userFullName != null && userFullName.trim().isNotEmpty)
          ? userFullName.trim()
          : (userEmail.isNotEmpty ? userEmail.split('@').first : 'Supplier'),
      email: userEmail,
      phoneNumber: userPhone,
      avatarUrl: userAvatar,
      location: (json['location'] as String?)?.trim(),
      bio: userBio,
      verificationStatus:
          (json['verification_status'] as String?)?.toLowerCase().trim() ??
              'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
