import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/remedy.dart';
import '../../domain/repositories/remedy_repository.dart';
import 'remedy_state.dart';

/// Cubit responsible for controlling the state
/// of the Remedy feature.
///
/// IMPORTANT:
///
/// RemedyCubit does NOT know about:
/// - Supabase
/// - RemedyRemoteDataSource
/// - RemedyModel
///
/// It only communicates with the DOMAIN repository.
class RemedyCubit extends Cubit<RemedyState> {
  /// Domain repository.
  final RemedyRepository repository;

  /// Keeps the complete list of remedies.
  ///
  /// We keep this inside the Cubit so that searching
  /// and filtering do not require fetching from Supabase every time.
  List<Remedy> _allRemedies = [];

  /// The currently applied condition filter ID.
  String? _currentConditionId;

  /// Constructor.
  ///
  /// The repository is injected from the widget tree.
  RemedyCubit(this.repository) : super(RemedyInitial());

  // ============================================================
  // LOAD REMEDIES
  // ============================================================

  /// Fetches all remedies from the repository.
  ///
  /// Flow:
  ///
  /// UI
  ///  ↓
  /// RemedyCubit
  ///  ↓
  /// RemedyRepository
  ///  ↓
  /// RemedyRepositoryImpl
  ///  ↓
  /// RemedyRemoteDataSource
  ///  ↓
  /// Supabase
  Future<void> loadRemedies() async {
    try {
      emit(RemedyLoading());

      final remedies = await repository.getAllRemedies();

      _allRemedies = remedies;
      _currentConditionId = null;

      emit(
        RemedyLoaded(
          remedies,
          searchQuery: '',
          filteredConditionId: null,
        ),
      );
    } catch (e) {
      emit(RemedyError('Failed to load remedies: $e'));
    }
  }

  // ============================================================
  // SEARCH REMEDIES
  // ============================================================

  /// Searches the remedies already loaded into memory.
  ///
  /// This is a local UI/business operation.
  ///
  /// We don't need to call Supabase for every character
  /// typed into the search box.
  void searchRemedies(String query) {
    final trimmedQuery = query.trim().toLowerCase();

    var filtered = _allRemedies;

    // Apply condition filter first (if active).
    if (_currentConditionId != null) {
      filtered = filtered
          .where((r) => r.conditionId == _currentConditionId)
          .toList();
    }

    // Apply search query against the generated display name and condition.
    if (trimmedQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (r) =>
                r.displayName.toLowerCase().contains(trimmedQuery) ||
                (r.conditionName?.toLowerCase().contains(trimmedQuery) ?? false),
          )
          .toList();
    }

    emit(
      RemedyLoaded(
        filtered,
        searchQuery: query,
        filteredConditionId: _currentConditionId,
      ),
    );
  }

  // ============================================================
  // FILTER BY CONDITION
  // ============================================================

  /// Filters remedies by a specific condition.
  ///
  /// Pass null to show all remedies.
  Future<void> filterByCondition(String? conditionId) async {
    try {
      emit(RemedyLoading());

      _currentConditionId = conditionId;

      if (conditionId == null) {
        final remedies = await repository.getAllRemedies();
        _allRemedies = remedies;
        emit(
          RemedyLoaded(
            remedies,
            searchQuery: '',
            filteredConditionId: null,
          ),
        );
      } else {
        final remedies = await repository.getRemediesByCondition(
          conditionId,
        );
        emit(
          RemedyLoaded(
            remedies,
            searchQuery: '',
            filteredConditionId: conditionId,
          ),
        );
      }
    } catch (e) {
      emit(RemedyError('Failed to filter remedies: $e'));
    }
  }

  // ============================================================
  // DELETE REMEDY
  // ============================================================

  /// Deletes a remedy.
  ///
  /// Notice:
  ///
  /// The Cubit does NOT directly call Supabase.
  ///
  /// It asks the repository to perform the operation.
  Future<void> deleteRemedy(String id) async {
    try {
      emit(RemedyLoading());

      await repository.deleteRemedy(id);

      _allRemedies.removeWhere((r) => r.id == id);

      emit(RemedyOperationSuccess('Remedy deleted successfully'));

      emit(
        RemedyLoaded(
          _allRemedies,
          searchQuery: '',
          filteredConditionId: _currentConditionId,
        ),
      );
    } catch (e) {
      emit(RemedyError('Failed to delete remedy: $e'));
    }
  }

  // ============================================================
  // APPROVE REMEDY
  // ============================================================

  /// Approves or disapproves a remedy.
  Future<void> approveRemedy(String id, {bool approved = true}) async {
    try {
      emit(RemedyLoading());

      await repository.approveRemedy(id, approved: approved);

      final message = approved ? 'Remedy approved' : 'Remedy unapproved';
      emit(RemedyOperationSuccess(message));

      await refreshRemedies();
    } catch (e) {
      emit(RemedyError('Failed to update approval status: $e'));
    }
  }

  // ============================================================
  // REFRESH REMEDIES
  // ============================================================

  /// Reloads remedies from the database.
  Future<void> refreshRemedies() async {
    await loadRemedies();
  }
}
