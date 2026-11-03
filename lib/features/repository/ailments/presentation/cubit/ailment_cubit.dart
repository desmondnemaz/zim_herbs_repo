import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/ailment.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/repositories/ailment_repository.dart';
import 'ailment_state.dart';

/// Cubit responsible for controlling state of the Ailment feature.
/// Operates solely with Domain contracts and entities.
class AilmentCubit extends Cubit<AilmentState> {
  final AilmentRepository repository;

  List<Ailment> _allAilments = [];
  List<BodyPart> _allBodyParts = [];
  String _currentQuery = '';
  AilmentCategory? _currentAilmentCategory;
  String? _currentBodyPartId;

  AilmentCubit(this.repository) : super(AilmentInitial());

  // ============================================================
  // LOAD AILMENTS & BODY PARTS
  // ============================================================
  Future<void> loadAilments() async {
    try {
      emit(AilmentLoading());
      final results = await Future.wait([
        repository.getAllAilments(),
        repository.getAllBodyParts(),
      ]);

      _allAilments = results[0] as List<Ailment>;
      _allBodyParts = results[1] as List<BodyPart>;
      _currentQuery = '';
      _currentAilmentCategory = null;
      _currentBodyPartId = null;

      emit(
        AilmentLoaded(
          _allAilments,
          allBodyParts: _allBodyParts,
          searchQuery: '',
          selectedAilmentCategory: null,
          selectedBodyPartId: null,
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message, failure: failure));
    }
  }

  // ============================================================
  // SEARCH & FILTER AILMENTS
  // ============================================================
  void searchAilments(String query) {
    _currentQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void filterByAilmentCategory(AilmentCategory? category) {
    _currentAilmentCategory = category;
    _applyFilters();
  }

  void filterByBodyPart(String? bodyPartId) {
    _currentBodyPartId = bodyPartId;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _allAilments;

    if (_currentAilmentCategory != null) {
      filtered = filtered
          .where((c) => c.ailmentCategory == _currentAilmentCategory)
          .toList();
    }

    if (_currentBodyPartId != null) {
      filtered = filtered
          .where((c) => c.bodyParts.any((bp) => bp.id == _currentBodyPartId))
          .toList();
    }

    if (_currentQuery.isNotEmpty) {
      filtered = filtered
          .where((c) => c.name.toLowerCase().contains(_currentQuery))
          .toList();
    }

    emit(
      AilmentLoaded(
        filtered,
        allBodyParts: _allBodyParts,
        searchQuery: _currentQuery,
        selectedAilmentCategory: _currentAilmentCategory,
        selectedBodyPartId: _currentBodyPartId,
      ),
    );
  }

  // ============================================================
  // CREATE AILMENT
  // ============================================================
  Future<void> createAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  }) async {
    try {
      emit(AilmentLoading());
      final created = await repository.createAilment(
        ailment,
        bodyPartIds: bodyPartIds,
      );
      _allAilments.add(created);
      _allAilments.sort((a, b) => a.name.compareTo(b.name));

      emit(AilmentOperationSuccess('Ailment created successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message));
    }
  }

  // ============================================================
  // UPDATE AILMENT
  // ============================================================
  Future<void> updateAilment(
    Ailment ailment, {
    List<String>? bodyPartIds,
  }) async {
    try {
      emit(AilmentLoading());
      final updated = await repository.updateAilment(
        ailment,
        bodyPartIds: bodyPartIds,
      );
      final index = _allAilments.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _allAilments[index] = updated;
      }
      _allAilments.sort((a, b) => a.name.compareTo(b.name));

      emit(AilmentOperationSuccess('Ailment updated successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message));
    }
  }

  // ============================================================
  // DELETE AILMENT
  // ============================================================
  Future<void> deleteAilment(String id) async {
    try {
      emit(AilmentLoading());
      await repository.deleteAilment(id);
      _allAilments.removeWhere((c) => c.id == id);

      emit(AilmentOperationSuccess('Ailment deleted successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message));
    }
  }

  // ============================================================
  // REFRESH AILMENTS
  // ============================================================
  Future<void> refreshAilments() async {
    await loadAilments();
  }

  /// Get list of cached or freshly fetched body parts
  Future<List<BodyPart>> getBodyParts() async {
    if (_allBodyParts.isNotEmpty) return _allBodyParts;
    _allBodyParts = await repository.getAllBodyParts();
    return _allBodyParts;
  }

  // ============================================================
  // BODY PART MUTATIONS
  // ============================================================
  Future<BodyPart> createBodyPart(BodyPart bodyPart) async {
    try {
      final created = await repository.createBodyPart(bodyPart);
      _allBodyParts.add(created);
      _allBodyParts.sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
      if (state is AilmentLoaded) {
        final current = state as AilmentLoaded;
        emit(
          AilmentLoaded(
            current.ailments,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedAilmentCategory: current.selectedAilmentCategory,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
      return created;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message, failure: failure));
      rethrow;
    }
  }

  Future<BodyPart> updateBodyPart(BodyPart bodyPart) async {
    try {
      final updated = await repository.updateBodyPart(bodyPart);
      final index = _allBodyParts.indexWhere((bp) => bp.id == updated.id);
      if (index != -1) {
        _allBodyParts[index] = updated;
      }
      _allBodyParts.sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
      if (state is AilmentLoaded) {
        final current = state as AilmentLoaded;
        emit(
          AilmentLoaded(
            current.ailments,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedAilmentCategory: current.selectedAilmentCategory,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
      return updated;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message, failure: failure));
      rethrow;
    }
  }

  Future<void> deleteBodyPart(String id) async {
    try {
      await repository.deleteBodyPart(id);
      _allBodyParts.removeWhere((bp) => bp.id == id);
      if (state is AilmentLoaded) {
        final current = state as AilmentLoaded;
        emit(
          AilmentLoaded(
            current.ailments,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedAilmentCategory: current.selectedAilmentCategory,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentError(failure.message, failure: failure));
      rethrow;
    }
  }

  // ============================================================
  // BACKWARD-COMPATIBLE ALIASES
  // ============================================================
  Future<void> loadConditions() => loadAilments();
  void searchConditions(String q) => searchAilments(q);
  void filterByBodySystem(BodySystem? sys) => filterByAilmentCategory(sys);
  Future<void> createCondition(Ailment c, {List<String>? bodyPartIds}) =>
      createAilment(c, bodyPartIds: bodyPartIds);
  Future<void> updateCondition(Ailment c, {List<String>? bodyPartIds}) =>
      updateAilment(c, bodyPartIds: bodyPartIds);
  Future<void> deleteCondition(String id) => deleteAilment(id);
  Future<void> refreshConditions() => refreshAilments();
}

/// Backward-compatible alias for legacy ConditionCubit
typedef ConditionCubit = AilmentCubit;
