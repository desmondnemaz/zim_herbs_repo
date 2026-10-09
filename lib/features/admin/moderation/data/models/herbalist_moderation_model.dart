/// Model representing a practitioner / herbalist profile for moderation
class HerbalistModerationModel {
  final String id; // References user_profiles.id
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? avatarUrl;
  final String specialisation;
  final int yearsOfExperience;
  final String? location;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final DateTime? createdAt;

  const HerbalistModerationModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.avatarUrl,
    required this.specialisation,
    required this.yearsOfExperience,
    this.location,
    required this.verificationStatus,
    this.createdAt,
  });

  bool get isVerified => verificationStatus.toLowerCase() == 'verified';
  bool get isPending =>
      verificationStatus.toLowerCase() == 'pending' ||
      verificationStatus.trim().isEmpty;
  bool get isRejected => verificationStatus.toLowerCase() == 'rejected';

  factory HerbalistModerationModel.fromJson(Map<String, dynamic> json) {
    final userProfile = json['user_profiles'] as Map<String, dynamic>?;

    final userFullName = userProfile?['full_name'] as String? ??
        (userProfile?['username'] as String?);
    final userEmail = userProfile?['email'] as String? ?? '';
    final userPhone = json['phone_number'] as String? ??
        userProfile?['phone_number'] as String?;
    final userAvatar = userProfile?['avatar_url'] as String?;

    return HerbalistModerationModel(
      id: json['id'] as String,
      fullName: (userFullName != null && userFullName.trim().isNotEmpty)
          ? userFullName.trim()
          : (userEmail.isNotEmpty ? userEmail.split('@').first : 'Practitioner'),
      email: userEmail,
      phoneNumber: userPhone,
      avatarUrl: userAvatar,
      specialisation:
          (json['specialisation'] as String?)?.trim() ?? 'General Herbalist',
      yearsOfExperience: (json['years_of_experience'] as num?)?.toInt() ?? 0,
      location: (json['location'] as String?)?.trim(),
      verificationStatus:
          (json['verification_status'] as String?)?.toLowerCase().trim() ??
              'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
