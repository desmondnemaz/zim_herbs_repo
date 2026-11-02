/// Pure business rules for building `user_profiles` role-update payloads.
///
/// Role model:
/// - **Administrator** (`is_admin`) and **Moderator** (`is_moderator`) are
///   independent roles stored in independent columns.
/// - Administrators can moderate *by virtue of being admins* (see
///   `UserModel.canModerate`), so granting admin must NOT write
///   `is_moderator = true`, and revoking admin must NOT touch `is_moderator`.
/// - `primary_role` is a display/label field. When the role it names
///   (`admin` / `moderator`) is revoked, it falls back to the highest role the
///   user still holds, or `household`.
///
/// Kept free of Flutter/Supabase imports so it can be unit-tested directly.
class RoleUpdateRules {
  const RoleUpdateRules._();

  /// Primary-role labels that represent a privilege which can be revoked.
  static const Set<String> privilegedPrimaryRoles = {'admin', 'moderator'};

  /// Highest remaining primary role for a user who no longer holds the role
  /// currently named in `primary_role`.
  static String fallbackPrimaryRole({
    required bool isAdmin,
    required bool isModerator,
    required bool isPractitioner,
    required bool isSupplier,
  }) {
    if (isAdmin) return 'admin';
    if (isModerator) return 'moderator';
    if (isPractitioner) return 'practitioner';
    if (isSupplier) return 'supplier';
    return 'household';
  }

  /// Payload for toggling the Administrator role only.
  static Map<String, dynamic> adminToggle({
    required Map<String, dynamic> user,
    required bool grant,
    required DateTime now,
  }) {
    final update = <String, dynamic>{
      'is_admin': grant,
      'updated_at': now.toIso8601String(),
    };
    if (grant) {
      update['primary_role'] = 'admin';
    } else if (user['primary_role'] == 'admin') {
      update['primary_role'] = fallbackPrimaryRole(
        isAdmin: false,
        isModerator: user['is_moderator'] == true,
        isPractitioner: user['is_practitioner'] == true,
        isSupplier: user['is_supplier'] == true,
      );
    }
    return update;
  }

  /// Payload for toggling the Moderator role only.
  static Map<String, dynamic> moderatorToggle({
    required Map<String, dynamic> user,
    required bool grant,
    required DateTime now,
  }) {
    final isAdmin = user['is_admin'] == true;
    final update = <String, dynamic>{
      'is_moderator': grant,
      'updated_at': now.toIso8601String(),
    };
    if (grant && !isAdmin) {
      update['primary_role'] = 'moderator';
    } else if (!grant && user['primary_role'] == 'moderator') {
      update['primary_role'] = fallbackPrimaryRole(
        isAdmin: isAdmin,
        isModerator: false,
        isPractitioner: user['is_practitioner'] == true,
        isSupplier: user['is_supplier'] == true,
      );
    }
    return update;
  }

  /// Payload for the combined "Manage User Rights" editor. Every flag is
  /// written exactly as chosen — no role implies another.
  static Map<String, dynamic> rightsUpdate({
    required String? currentPrimaryRole,
    required bool isAdmin,
    required bool isModerator,
    required bool isPractitioner,
    required bool isSupplier,
    required bool isActive,
    required DateTime now,
  }) {
    final update = <String, dynamic>{
      'is_admin': isAdmin,
      'is_moderator': isModerator,
      'is_practitioner': isPractitioner,
      'is_supplier': isSupplier,
      'is_active': isActive,
      'updated_at': now.toIso8601String(),
    };
    final holdsAnyRole = isAdmin || isModerator || isPractitioner || isSupplier;
    if (holdsAnyRole ||
        privilegedPrimaryRoles.contains(currentPrimaryRole)) {
      update['primary_role'] = fallbackPrimaryRole(
        isAdmin: isAdmin,
        isModerator: isModerator,
        isPractitioner: isPractitioner,
        isSupplier: isSupplier,
      );
    }
    return update;
  }
}
