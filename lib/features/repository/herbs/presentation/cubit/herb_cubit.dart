import 'package:flutter_bloc/flutter_bloc.dart';

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
    } catch (e) {
      /// Something went wrong.
      emit(
        HerbError(e.toString()),
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
    } catch (e) {
      /// Tell the UI that deletion failed.
      emit(
        HerbError(e.toString()),
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
}