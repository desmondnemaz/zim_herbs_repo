import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/condition.dart';
import '../../domain/repositories/condition_repository.dart';
import 'condition_state.dart';

/// Cubit responsible for controlling state of the Condition feature.
/// Operates solely with Domain contracts and entities.
class ConditionCubit extends Cubit<ConditionState> {
  final ConditionRepository repository;

  List<Condition> _allConditions = [];
  String _currentQuery = '';
  BodySystem? _currentBodySystem;

  ConditionCubit(this.repository) : super(ConditionInitial());

  // ============================================================
  // LOAD CONDITIONS
  // ============================================================
  Future<void> loadConditions() async {
    try {
      emit(ConditionLoading());
      final conditions = await repository.getAllConditions();
      _allConditions = conditions;
      _currentQuery = '';
      _currentBodySystem = null;

      emit(
        ConditionLoaded(
          _allConditions,
          searchQuery: '',
          selectedBodySystem: null,
        ),
      );
    } catch (e) {
      emit(ConditionError(e.toString()));
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

  void _applyFilters() {
    var filtered = _allConditions;

    if (_currentBodySystem != null) {
      filtered = filtered
          .where((c) => c.bodySystem == _currentBodySystem)
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
        searchQuery: _currentQuery,
        selectedBodySystem: _currentBodySystem,
      ),
    );
  }

  // ============================================================
  // CREATE CONDITION
  // ============================================================
  Future<void> createCondition(Condition condition) async {
    try {
      emit(ConditionLoading());
      final created = await repository.createCondition(condition);
      _allConditions.add(created);
      _allConditions.sort((a, b) => a.name.compareTo(b.name));

      emit(ConditionOperationSuccess('Condition created successfully'));
      _applyFilters();
    } catch (e) {
      emit(ConditionError(e.toString()));
    }
  }

  // ============================================================
  // UPDATE CONDITION
  // ============================================================
  Future<void> updateCondition(Condition condition) async {
    try {
      emit(ConditionLoading());
      final updated = await repository.updateCondition(condition);
      final index = _allConditions.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _allConditions[index] = updated;
      }
      _allConditions.sort((a, b) => a.name.compareTo(b.name));

      emit(ConditionOperationSuccess('Condition updated successfully'));
      _applyFilters();
    } catch (e) {
      emit(ConditionError(e.toString()));
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
    } catch (e) {
      emit(ConditionError(e.toString()));
    }
  }

  // ============================================================
  // REFRESH CONDITIONS
  // ============================================================
  Future<void> refreshConditions() async {
    await loadConditions();
  }
}
