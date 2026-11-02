import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/condition.dart';
import '../../domain/repositories/condition_repository.dart';
import 'condition_state.dart';

/// Cubit responsible for controlling state of the Condition feature.
/// Operates solely with Domain contracts and entities.
class ConditionCubit extends Cubit<ConditionState> {
  final ConditionRepository repository;

  List<Condition> _allConditions = [];
  List<BodyPart> _allBodyParts = [];
  String _currentQuery = '';
  BodySystem? _currentBodySystem;
  String? _currentBodyPartId;

  ConditionCubit(this.repository) : super(ConditionInitial());

  // ============================================================
  // LOAD CONDITIONS & BODY PARTS
  // ============================================================
  Future<void> loadConditions() async {
    try {
      emit(ConditionLoading());
      final results = await Future.wait([
        repository.getAllConditions(),
        repository.getAllBodyParts(),
      ]);

      _allConditions = results[0] as List<Condition>;
      _allBodyParts = results[1] as List<BodyPart>;
      _currentQuery = '';
      _currentBodySystem = null;
      _currentBodyPartId = null;

      emit(
        ConditionLoaded(
          _allConditions,
          allBodyParts: _allBodyParts,
          searchQuery: '',
          selectedBodySystem: null,
          selectedBodyPartId: null,
        ),
      );
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message, failure: failure));
    }
  }

  // ============================================================
  // SEARCH & FILTER CONDITIONS
  // ============================================================
  void searchConditions(String query) {
    _currentQuery = query.trim().toLowerCase();
    _applyFilters();
  }

  void filterByBodySystem(BodySystem? bodySystem) {
    _currentBodySystem = bodySystem;
    _applyFilters();
  }

  void filterByBodyPart(String? bodyPartId) {
    _currentBodyPartId = bodyPartId;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _allConditions;

    if (_currentBodySystem != null) {
      filtered = filtered
          .where((c) => c.bodySystem == _currentBodySystem)
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
      ConditionLoaded(
        filtered,
        allBodyParts: _allBodyParts,
        searchQuery: _currentQuery,
        selectedBodySystem: _currentBodySystem,
        selectedBodyPartId: _currentBodyPartId,
      ),
    );
  }

  // ============================================================
  // CREATE CONDITION
  // ============================================================
  Future<void> createCondition(
    Condition condition, {
    List<String>? bodyPartIds,
  }) async {
    try {
      emit(ConditionLoading());
      final created = await repository.createCondition(
        condition,
        bodyPartIds: bodyPartIds,
      );
      _allConditions.add(created);
      _allConditions.sort((a, b) => a.name.compareTo(b.name));

      emit(ConditionOperationSuccess('Condition created successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message));
    }
  }

  // ============================================================
  // UPDATE CONDITION
  // ============================================================
  Future<void> updateCondition(
    Condition condition, {
    List<String>? bodyPartIds,
  }) async {
    try {
      emit(ConditionLoading());
      final updated = await repository.updateCondition(
        condition,
        bodyPartIds: bodyPartIds,
      );
      final index = _allConditions.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _allConditions[index] = updated;
      }
      _allConditions.sort((a, b) => a.name.compareTo(b.name));

      emit(ConditionOperationSuccess('Condition updated successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message));
    }
  }

  // ============================================================
  // DELETE CONDITION
  // ============================================================
  Future<void> deleteCondition(String id) async {
    try {
      emit(ConditionLoading());
      await repository.deleteCondition(id);
      _allConditions.removeWhere((c) => c.id == id);

      emit(ConditionOperationSuccess('Condition deleted successfully'));
      _applyFilters();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message));
    }
  }

  // ============================================================
  // REFRESH CONDITIONS
  // ============================================================
  Future<void> refreshConditions() async {
    await loadConditions();
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
      if (state is ConditionLoaded) {
        final current = state as ConditionLoaded;
        emit(
          ConditionLoaded(
            current.conditions,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedBodySystem: current.selectedBodySystem,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
      return created;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message, failure: failure));
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
      if (state is ConditionLoaded) {
        final current = state as ConditionLoaded;
        emit(
          ConditionLoaded(
            current.conditions,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedBodySystem: current.selectedBodySystem,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
      return updated;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message, failure: failure));
      rethrow;
    }
  }

  Future<void> deleteBodyPart(String id) async {
    try {
      await repository.deleteBodyPart(id);
      _allBodyParts.removeWhere((bp) => bp.id == id);
      if (state is ConditionLoaded) {
        final current = state as ConditionLoaded;
        emit(
          ConditionLoaded(
            current.conditions,
            allBodyParts: List<BodyPart>.from(_allBodyParts),
            searchQuery: current.searchQuery,
            selectedBodySystem: current.selectedBodySystem,
            selectedBodyPartId: current.selectedBodyPartId,
          ),
        );
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionError(failure.message, failure: failure));
      rethrow;
    }
  }
}
