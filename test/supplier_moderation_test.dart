import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/admin/moderation/data/models/supplier_moderation_model.dart';

void main() {
  group('SupplierModerationModel Unit Tests', () {
    test('Correctly parses from Supabase joined JSON with pending status', () {
      final json = {
        'id': 'user-123-abc',
        'supplier_name': 'ZimNatural Farms',
        'location': 'Bindura, Zimbabwe',
        'verification_status': 'pending',
        'created_at': '2026-11-01T12:00:00.000Z',
        'user_profiles': {
          'id': 'user-123-abc',
          'full_name': 'Tapiwa Moyo',
          'username': 'tmoyo',
          'email': 'tapiwa@example.com',
          'phone_number': '+263771234567',
          'avatar_url': 'https://example.com/avatar.jpg',
          'bio': 'Sustainable wildcrafter of resurrection bush and baobab oil',
        },
      };

      final model = SupplierModerationModel.fromJson(json);

      expect(model.id, equals('user-123-abc'));
      expect(model.supplierName, equals('ZimNatural Farms'));
      expect(model.fullName, equals('Tapiwa Moyo'));
      expect(model.email, equals('tapiwa@example.com'));
      expect(model.phoneNumber, equals('+263771234567'));
      expect(model.location, equals('Bindura, Zimbabwe'));
      expect(model.bio, contains('Sustainable wildcrafter'));
      expect(model.isPending, isTrue);
      expect(model.isVerified, isFalse);
      expect(model.isRejected, isFalse);
    });

    test('Correctly identifies verified and approved supplier status', () {
      final json = {
        'id': 'user-456-def',
        'supplier_name': 'Baobab Collective',
        'location': 'Chiredzi, Zimbabwe',
        'verification_status': 'verified',
        'created_at': '2026-10-15T08:30:00.000Z',
        'user_profiles': {
          'id': 'user-456-def',
          'full_name': 'Farai Chikwanha',
          'email': 'farai@baobab.co.zw',
        },
      };

      final model = SupplierModerationModel.fromJson(json);

      expect(model.supplierName, equals('Baobab Collective'));
      expect(model.verificationStatus, equals('verified'));
      expect(model.isVerified, isTrue);
      expect(model.isPending, isFalse);
      expect(model.isRejected, isFalse);
    });

    test('Correctly identifies rejected supplier application status', () {
      final json = {
        'id': 'user-789-ghi',
        'supplier_name': 'Unverified Trader',
        'location': 'Harare, Zimbabwe',
        'verification_status': 'rejected',
        'created_at': '2026-10-20T10:00:00.000Z',
        'user_profiles': {
          'id': 'user-789-ghi',
          'email': 'trader@unverified.com',
        },
      };

      final model = SupplierModerationModel.fromJson(json);

      expect(model.isRejected, isTrue);
      expect(model.isVerified, isFalse);
      expect(model.isPending, isFalse);
    });
  });
}
