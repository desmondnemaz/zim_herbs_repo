import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
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
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
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
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
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
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
    }
  }

  /// Deletes multiple remedies in a single batch operation.
  Future<void> deleteRemedies(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      emit(RemedyLoading());

      await repository.deleteRemedies(ids);

      _allRemedies.removeWhere((r) => ids.contains(r.id));

      final count = ids.length;
      emit(RemedyOperationSuccess(
        '$count ${count == 1 ? 'remedy' : 'remedies'} deleted successfully',
      ));

      emit(
        RemedyLoaded(
          _allRemedies,
          searchQuery: '',
          filteredConditionId: _currentConditionId,
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
    }
  }

  // ============================================================
  // APPROVE / VERIFY REMEDY
  // ============================================================

  /// Approves or disapproves a remedy.
  Future<void> approveRemedy(
    String id, {
    bool approved = true,
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    try {
      emit(RemedyLoading());

      await repository.approveRemedy(
        id,
        approved: approved,
        verifiedBy: verifiedBy,
        moderationNotes: moderationNotes,
      );

      final message = approved
          ? 'Remedy approved and published'
          : 'Remedy marked as unapproved';
      emit(RemedyOperationSuccess(message));

      await refreshRemedies();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
    }
  }

  /// Updates remedy verification status with audit traceability.
  Future<void> updateRemedyVerification(
    String remedyId,
    bool isApproved, {
    String? verifiedBy,
    String? moderationNotes,
  }) async {
    await approveRemedy(
      remedyId,
      approved: isApproved,
      verifiedBy: verifiedBy,
      moderationNotes: moderationNotes,
    );
  }

  /// Unpublishes an active remedy, moving it to validated, under_review, or archived.
  Future<void> unpublishRemedy(
    String id, {
    RecordValidationStatus targetStatus = RecordValidationStatus.validated,
    String? moderatorId,
    String? reason,
  }) async {
    try {
      await repository.unpublishRemedy(
        id,
        targetStatus: targetStatus,
        moderatorId: moderatorId,
        reason: reason,
      );
      emit(RemedyOperationSuccess('Remedy unpublished (${targetStatus.label})'));
      await loadRemedies();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyError(failure.message, failure: failure));
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
