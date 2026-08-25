import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import 'treatment_state.dart';


/// Cubit responsible for controlling the state
/// of the Treatment feature.
///
/// IMPORTANT:
///
/// TreatmentCubit does NOT know about:
/// - Supabase
/// - TreatmentRemoteDataSource
/// - TreatmentModel
///
/// It only communicates with the DOMAIN repository.
class TreatmentCubit extends Cubit<TreatmentState> {
  /// Domain repository.
  final TreatmentRepository repository;

  /// Keeps the complete list of treatments.
  ///
  /// We keep this inside the Cubit so that searching
  /// and filtering do not require fetching from Supabase every time.
  List<Treatment> _allTreatments = [];

  /// The currently applied condition filter ID.
  String? _currentConditionId;


  /// Constructor.
  ///
  /// The repository is injected from the widget tree.
  TreatmentCubit(this.repository) : super(TreatmentInitial());


  // ============================================================
  // LOAD TREATMENTS
  // ============================================================

  /// Fetches all treatments from the repository.
  ///
  /// Flow:
  ///
  /// UI
  ///  ↓
  /// TreatmentCubit
  ///  ↓
  /// TreatmentRepository
  ///  ↓
  /// TreatmentRepositoryImpl
  ///  ↓
  /// TreatmentRemoteDataSource
  ///  ↓
  /// Supabase
  Future<void> loadTreatments() async {
    try {
      emit(TreatmentLoading());

      final treatments = await repository.getAllTreatments();

      _allTreatments = treatments;
      _currentConditionId = null;

      emit(
        TreatmentLoaded(
          treatments,
          searchQuery: '',
          filteredConditionId: null,
        ),
      );
    } catch (e) {
      emit(TreatmentError('Failed to load treatments: $e'));
    }
  }


  // ============================================================
  // SEARCH TREATMENTS
  // ============================================================

  /// Searches the treatments already loaded into memory.
  ///
  /// This is a local UI/business operation.
  ///
  /// We don't need to call Supabase for every character
  /// typed into the search box.
  void searchTreatments(String query) {
    final trimmedQuery = query.trim().toLowerCase();

    var filtered = _allTreatments;

    // Apply condition filter first (if active).
    if (_currentConditionId != null) {
      filtered = filtered
          .where((t) => t.conditionId == _currentConditionId)
          .toList();
    }

    // Apply search query against the generated display name and condition.
    if (trimmedQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.displayName.toLowerCase().contains(trimmedQuery) ||
                (t.conditionName?.toLowerCase().contains(trimmedQuery) ?? false),
          )
          .toList();
    }

    emit(
      TreatmentLoaded(
        filtered,
        searchQuery: query,
        filteredConditionId: _currentConditionId,
      ),
    );
  }


  // ============================================================
  // FILTER BY CONDITION
  // ============================================================

  /// Filters treatments by a specific condition.
  ///
  /// Pass null to show all treatments.
  Future<void> filterByCondition(String? conditionId) async {
    try {
      emit(TreatmentLoading());

      _currentConditionId = conditionId;

      if (conditionId == null) {
        final treatments = await repository.getAllTreatments();
        _allTreatments = treatments;
        emit(
          TreatmentLoaded(
            treatments,
            searchQuery: '',
            filteredConditionId: null,
          ),
        );
      } else {
        final treatments = await repository.getTreatmentsByCondition(
          conditionId,
        );
        emit(
          TreatmentLoaded(
            treatments,
            searchQuery: '',
            filteredConditionId: conditionId,
          ),
        );
      }
    } catch (e) {
      emit(TreatmentError('Failed to filter treatments: $e'));
    }
  }


  // ============================================================
  // DELETE TREATMENT
  // ============================================================

  /// Deletes a treatment.
  ///
  /// Notice:
  ///
  /// The Cubit does NOT directly call Supabase.
  ///
  /// It asks the repository to perform the operation.
  Future<void> deleteTreatment(String id) async {
    try {
      emit(TreatmentLoading());

      await repository.deleteTreatment(id);

      _allTreatments.removeWhere((t) => t.id == id);

      emit(TreatmentOperationSuccess('Treatment deleted successfully'));

      emit(
        TreatmentLoaded(
          _allTreatments,
          searchQuery: '',
          filteredConditionId: _currentConditionId,
        ),
      );
    } catch (e) {
      emit(TreatmentError('Failed to delete treatment: $e'));
    }
  }


  // ============================================================
  // APPROVE TREATMENT
  // ============================================================

  /// Approves or disapproves a treatment.
  Future<void> approveTreatment(String id, {bool approved = true}) async {
    try {
      emit(TreatmentLoading());

      await repository.approveTreatment(id, approved: approved);

      final message = approved ? 'Treatment approved' : 'Treatment unapproved';
      emit(TreatmentOperationSuccess(message));

      await refreshTreatments();
    } catch (e) {
      emit(TreatmentError('Failed to update approval status: $e'));
    }
  }


  // ============================================================
  // REFRESH TREATMENTS
  // ============================================================

  /// Reloads treatments from the database.
  Future<void> refreshTreatments() async {
    await loadTreatments();
  }
}
