import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/admin/user_management/domain/role_update_rules.dart';

void main() {
  final now = DateTime(2026, 11, 2, 8);

  group('RoleUpdateRules.adminToggle', () {
    test('granting admin does not write is_moderator', () {
      final update = RoleUpdateRules.adminToggle(
        user: {'is_admin': false, 'is_moderator': false, 'primary_role': 'household'},
        grant: true,
        now: now,
      );
      expect(update['is_admin'], isTrue);
      expect(update['primary_role'], 'admin');
      expect(update.containsKey('is_moderator'), isFalse);
    });

    test('revoking admin does not touch is_moderator', () {
      final update = RoleUpdateRules.adminToggle(
        user: {'is_admin': true, 'is_moderator': true, 'primary_role': 'admin'},
        grant: false,
        now: now,
      );
      expect(update['is_admin'], isFalse);
      expect(update.containsKey('is_moderator'), isFalse);
    });

    test('revoking admin resets primary_role to moderator when held', () {
      final update = RoleUpdateRules.adminToggle(
        user: {'is_admin': true, 'is_moderator': true, 'primary_role': 'admin'},
        grant: false,
        now: now,
      );
      expect(update['primary_role'], 'moderator');
    });

    test('revoking admin falls back to household when no other role', () {
      final update = RoleUpdateRules.adminToggle(
        user: {'is_admin': true, 'is_moderator': false, 'primary_role': 'admin'},
        grant: false,
        now: now,
      );
      expect(update['primary_role'], 'household');
    });

    test('revoking admin keeps a non-admin primary_role unchanged', () {
      final update = RoleUpdateRules.adminToggle(
        user: {'is_admin': true, 'primary_role': 'practitioner'},
        grant: false,
        now: now,
      );
      expect(update.containsKey('primary_role'), isFalse);
    });
  });

  group('RoleUpdateRules.moderatorToggle', () {
    test('revoking moderator from an admin keeps admin untouched', () {
      final update = RoleUpdateRules.moderatorToggle(
        user: {'is_admin': true, 'is_moderator': true, 'primary_role': 'admin'},
        grant: false,
        now: now,
      );
      expect(update['is_moderator'], isFalse);
      expect(update.containsKey('is_admin'), isFalse);
      expect(update.containsKey('primary_role'), isFalse);
    });

    test('revoking moderator resets a moderator primary_role', () {
      final update = RoleUpdateRules.moderatorToggle(
        user: {'is_admin': false, 'is_moderator': true, 'is_practitioner': true, 'primary_role': 'moderator'},
        grant: false,
        now: now,
      );
      expect(update['primary_role'], 'practitioner');
    });

    test('granting moderator to an admin keeps primary_role admin', () {
      final update = RoleUpdateRules.moderatorToggle(
        user: {'is_admin': true, 'is_moderator': false, 'primary_role': 'admin'},
        grant: true,
        now: now,
      );
      expect(update['is_moderator'], isTrue);
      expect(update.containsKey('primary_role'), isFalse);
    });
  });

  group('RoleUpdateRules.rightsUpdate', () {
    test('admin without moderator is persisted exactly as chosen', () {
      final update = RoleUpdateRules.rightsUpdate(
        currentPrimaryRole: 'household',
        isAdmin: true,
        isModerator: false,
        isPractitioner: false,
        isSupplier: false,
        isActive: true,
        now: now,
      );
      expect(update['is_admin'], isTrue);
      expect(update['is_moderator'], isFalse);
      expect(update['primary_role'], 'admin');
    });

    test('removing all roles from an admin resets primary_role to household', () {
      final update = RoleUpdateRules.rightsUpdate(
        currentPrimaryRole: 'admin',
        isAdmin: false,
        isModerator: false,
        isPractitioner: false,
        isSupplier: false,
        isActive: true,
        now: now,
      );
      expect(update['primary_role'], 'household');
    });

    test('pending supplier applicant label is preserved when no roles held', () {
      final update = RoleUpdateRules.rightsUpdate(
        currentPrimaryRole: 'supplier',
        isAdmin: false,
        isModerator: false,
        isPractitioner: false,
        isSupplier: false,
        isActive: true,
        now: now,
      );
      expect(update.containsKey('primary_role'), isFalse);
    });
  });
}
