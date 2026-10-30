import 'package:flutter_test/flutter_test.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_state.dart';
import 'package:zim_herbs_repo/features/auth/domain/user_model.dart';

class FakeHerbRepository implements HerbRepository {
  List<Herb> herbs;
  List<String> lastDeletedBatch = [];

  FakeHerbRepository(this.herbs);

  @override
  Future<List<Herb>> getAllHerbs() async => List.from(herbs);

  @override
  Future<int> getHerbsCount() async => herbs.length;

  @override
  Future<Herb> getHerbById(String id) async => herbs.firstWhere((h) => h.id == id);

  @override
  Future<Herb> createHerb(Herb herb) async => herb;

  @override
  Future<Herb> updateHerb(Herb herb) async => herb;

  @override
  Future<void> deleteHerb(String id) async {
    herbs.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> deleteHerbs(List<String> ids) async {
    lastDeletedBatch = List.from(ids);
    herbs.removeWhere((h) => ids.contains(h.id));
  }

  @override
  Future<List<Herb>> getUnverifiedHerbs() async {
    return herbs.where((h) => !h.isApproved).toList();
  }

  @override
  Future<void> updateHerbVerification(
    String herbId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    final idx = herbs.indexWhere((h) => h.id == herbId);
    if (idx != -1) {
      final h = herbs[idx];
      herbs[idx] = Herb(
        id: h.id,
        nameEn: h.nameEn,
        nameSn: h.nameSn,
        nameNd: h.nameNd,
        description: h.description,
        isApproved: isApproved,
        createdBy: h.createdBy,
        updatedBy: verifiedBy ?? h.updatedBy,
        verifiedBy: isApproved ? verifiedBy : null,
        verifiedAt: isApproved ? DateTime.now() : null,
        moderationNotes: moderationNotes ?? h.moderationNotes,
      );
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HerbCubit tests', () {
    late FakeHerbRepository fakeRepo;
    late HerbCubit cubit;

    setUp(() {
      fakeRepo = FakeHerbRepository([
        const Herb(id: '1', nameEn: 'Herb One', isApproved: true),
        const Herb(id: '2', nameEn: 'Herb Two', isApproved: false),
        const Herb(id: '3', nameEn: 'Herb Three', isApproved: true),
      ]);
      cubit = HerbCubit(fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('loadHerbs emits HerbLoading then HerbLoaded', () async {
      await cubit.loadHerbs();
      expect(cubit.state, isA<HerbLoaded>());
      final loaded = cubit.state as HerbLoaded;
      expect(loaded.herbs.length, 3);
    });

    test('loadUnverifiedHerbs loads only herbs where isApproved is false', () async {
      await cubit.loadUnverifiedHerbs();
      expect(cubit.state, isA<HerbLoaded>());
      final loaded = cubit.state as HerbLoaded;
      expect(loaded.herbs.length, 1);
      expect(loaded.herbs.first.id, '2');
      expect(loaded.herbs.first.isApproved, isFalse);
    });

    test('updateHerbVerification verifies herb and emits HerbOperationSuccess', () async {
      await cubit.loadHerbs();

      final states = <HerbState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.updateHerbVerification('2', true);
      await Future<void>.delayed(Duration.zero);

      expect(states.any((s) => s is HerbOperationSuccess && s.message.contains('verified')), isTrue);
      final loaded = cubit.state as HerbLoaded;
      expect(loaded.herbs.firstWhere((h) => h.id == '2').isApproved, isTrue);

      await subscription.cancel();
    });

    test('deleteHerbs removes marked herbs and emits HerbOperationSuccess then HerbLoaded', () async {
      await cubit.loadHerbs();

      final states = <HerbState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.deleteHerbs(['1', '3']);
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepo.lastDeletedBatch, ['1', '3']);
      expect(states.any((s) => s is HerbOperationSuccess && s.message.contains('2 herbs deleted')), isTrue);

      final finalState = cubit.state as HerbLoaded;
      expect(finalState.herbs.length, 1);
      expect(finalState.herbs.first.id, '2');

      await subscription.cancel();
    });
  });

  group('Admin Moderation Rights', () {
    test('UserRole.admin inherits isModerator rights', () {
      expect(UserRole.admin.isModerator, isTrue);
      expect(UserRole.moderator.isModerator, isTrue);
      expect(UserRole.customer.isModerator, isFalse);
    });

    test('UserModel with isAdmin=true automatically has isModerator=true and canModerate=true', () {
      const adminUser = UserModel(
        id: 'admin_1',
        name: 'Admin User',
        email: 'admin@zimherbs.co.zw',
        role: UserRole.admin,
        isAdmin: true,
      );

      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.isModerator, isTrue);
      expect(adminUser.canModerate, isTrue);
      expect(adminUser.canManageUsers, isTrue);
    });

    test('UserModel.fromJson parses admin and grants moderation rights', () {
      final json = {
        'id': 'u100',
        'name': 'Super Admin',
        'email': 'super@zimherbs.co.zw',
        'is_admin': true,
        'is_moderator': false, // Even if false in DB JSON, admin inherits rights
      };

      final user = UserModel.fromJson(json);
      expect(user.isAdmin, isTrue);
      expect(user.isModerator, isTrue);
      expect(user.canModerate, isTrue);
    });
  });
}
