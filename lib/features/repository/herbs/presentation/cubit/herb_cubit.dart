import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';

import '../../domain/entities/herb.dart';
import '../../domain/repositories/herb_repository.dart';
import 'herb_state.dart';


/// Cubit responsible for controlling the state
/// of the Herb feature.
///
/// IMPORTANT:
///
/// HerbCubit does NOT know about:
/// - Supabase
/// - HerbRemoteDataSource
/// - HerbModel
///
/// It only communicates with the DOMAIN repository.
class HerbCubit extends Cubit<HerbState> {
  /// Domain repository.
  final HerbRepository repository;


  /// Keeps the complete list of herbs.
  ///
  /// We keep this inside the Cubit so that searching
  /// does not require fetching from Supabase every time.
  List<Herb> _allHerbs = [];


  /// Constructor.
  ///
  /// The repository is injected from app.dart.
  HerbCubit(this.repository) : super(HerbInitial());


  // ============================================================
  // LOAD HERBS
  // ============================================================

  /// Fetches all herbs from the repository.
  ///
  /// Flow:
  ///
  /// UI
  ///  ↓
  /// HerbCubit
  ///  ↓
  /// HerbRepository
  ///  ↓
  /// HerbRepositoryImpl
  ///  ↓
  /// HerbRemoteDataSource
  ///  ↓
  /// Supabase
  Future<void> loadHerbs() async {
    try {
      /// Tell the UI that loading has started.
      emit(HerbLoading());


      /// Ask the domain repository for the herbs.
      final herbs = await repository.getAllHerbs();


      /// Keep a copy for searching.
      _allHerbs = herbs;


      /// Send the domain entities to the UI.
      emit(
        HerbLoaded(
          herbs,
          searchQuery: '',
        ),
      );
    } catch (e, stackTrace) {
      /// Something went wrong.
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(
        HerbError(failure.message, failure: failure),
      );
    }
  }


  // ============================================================
  // SEARCH HERBS
  // ============================================================

  /// Searches the herbs already loaded into memory.
  ///
  /// This is a local UI/business operation.
  ///
  /// We don't need to call Supabase for every character
  /// typed into the search box.
  void searchHerbs(String query) {
    final trimmedQuery = query.trim().toLowerCase();


    /// If search is empty, display everything.
    if (trimmedQuery.isEmpty) {
      emit(
        HerbLoaded(
          _allHerbs,
          searchQuery: '',
        ),
      );

      return;
    }


    /// Filter the herbs.
    final filteredHerbs = _allHerbs.where((herb) {
      return herb.nameEn.toLowerCase().contains(trimmedQuery) ||
          (herb.nameSn?.toLowerCase().contains(trimmedQuery) ?? false) ||
          (herb.nameNd?.toLowerCase().contains(trimmedQuery) ?? false);
    }).toList();


    /// Give the filtered list to the UI.
    emit(
      HerbLoaded(
        filteredHerbs,
        searchQuery: query,
      ),
    );
  }


  // ============================================================
  // DELETE HERB
  // ============================================================

  /// Deletes a herb.
  ///
  /// Notice:
  ///
  /// The Cubit does NOT directly call Supabase.
  ///
  /// It asks the repository to perform the operation.
  Future<void> deleteHerb(String id) async {
    try {
      /// Tell the UI that an operation is happening.
      emit(HerbLoading());


      /// Ask the repository to delete the herb.
      await repository.deleteHerb(id);


      /// Remove the herb from our local list.
      _allHerbs.removeWhere(
        (herb) => herb.id == id,
      );


      /// Tell the UI that the operation succeeded.
      emit(
        HerbOperationSuccess(
          'Herb deleted successfully',
        ),
      );


      /// Display the updated list.
      emit(
        HerbLoaded(
          _allHerbs,
          searchQuery: '',
        ),
      );
    } catch (e, stackTrace) {
      /// Tell the UI that deletion failed.
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(
        HerbError(failure.message, failure: failure),
      );
    }
  }


  // ============================================================
  // DELETE MULTIPLE HERBS
  // ============================================================

  /// Deletes multiple herbs.
  Future<void> deleteHerbs(List<String> ids) async {
    if (ids.isEmpty) return;

    try {
      /// Tell the UI that an operation is happening.
      emit(HerbLoading());

      /// Ask the repository to delete the herbs.
      await repository.deleteHerbs(ids);

      /// Remove the herbs from our local list.
      final idSet = ids.toSet();
      _allHerbs.removeWhere(
        (herb) => idSet.contains(herb.id),
      );

      /// Tell the UI that the operation succeeded.
      emit(
        HerbOperationSuccess(
          '${ids.length} herb${ids.length > 1 ? 's' : ''} deleted successfully',
        ),
      );

      /// Display the updated list.
      emit(
        HerbLoaded(
          _allHerbs,
          searchQuery: '',
        ),
      );
    } catch (e, stackTrace) {
      /// Tell the UI that deletion failed.
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(
        HerbError(failure.message, failure: failure),
      );
    }
  }


  // ============================================================
  // REFRESH HERBS
  // ============================================================

  /// Reloads herbs from the database.
  ///
  /// This replaces the old:
  ///
  ///     RefreshHerbs()
  ///
  /// BLoC event.
  Future<void> refreshHerbs() async {
    await loadHerbs();
  }

  // ============================================================
  // UNVERIFIED HERBS OPERATIONS
  // ============================================================

  /// Fetches only unverified herbs pending moderator review.
  Future<void> loadUnverifiedHerbs() async {
    try {
      emit(HerbLoading());
      final herbs = await repository.getUnverifiedHerbs();
      _allHerbs = herbs;
      emit(HerbLoaded(herbs, searchQuery: ''));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(HerbError(failure.message, failure: failure));
    }
  }

  /// Updates an herb's verification status (approves or revokes).
  Future<void> updateHerbVerification(
    String herbId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    try {
      await repository.updateHerbVerification(
        herbId,
        isApproved,
        verifiedBy: verifiedBy,
        moderationNotes: moderationNotes,
      );
      final index = _allHerbs.indexWhere((h) => h.id == herbId);
      if (index != -1) {
        final current = _allHerbs[index];
        _allHerbs[index] = Herb(
          id: current.id,
          nameEn: current.nameEn,
          nameSn: current.nameSn,
          nameNd: current.nameNd,
          description: current.description,
          isApproved: isApproved,
          images: current.images,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          createdBy: current.createdBy,
          updatedBy: verifiedBy ?? current.updatedBy,
          verifiedBy: isApproved ? verifiedBy : null,
          verifiedAt: isApproved ? DateTime.now() : null,
          moderationNotes: moderationNotes ?? current.moderationNotes,
        );
      }
      emit(
        HerbOperationSuccess(
          isApproved ? 'Herb verified and published' : 'Herb marked as unverified',
        ),
      );
      emit(HerbLoaded(_allHerbs, searchQuery: ''));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(HerbError(failure.message, failure: failure));
    }
  }
}