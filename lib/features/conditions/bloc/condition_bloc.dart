import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/condition_repository.dart';
import 'package:zim_herbs_repo/features/conditions/bloc/condition_event.dart';
import 'package:zim_herbs_repo/features/conditions/bloc/condition_state.dart';

/// The "Chef" for the Conditions screen.
/// It takes an Event (Order), talks to the Repository, and returns a State (Meal).
class ConditionBloc extends Bloc<ConditionEvent, ConditionState> {
  final ConditionRepository _repository;

  ConditionBloc(this._repository) : super(ConditionInitial()) {
    // Map our Orders to the right Functions
    on<LoadConditions>(_onLoadConditions);
    on<SearchConditions>(_onSearchConditions);
    on<RefreshConditions>(_onRefreshConditions);
  }

  /// Logic for loading the initial list
  Future<void> _onLoadConditions(
    LoadConditions event,
    Emitter<ConditionState> emit,
  ) async {
    emit(ConditionLoading());
    try {
      final conditions = await _repository.getAllConditions();
      emit(ConditionLoaded(conditions));
    } catch (e) {
      emit(ConditionError("Failed to load conditions: $e"));
    }
  }

  /// Logic for searching/filtering
  Future<void> _onSearchConditions(
    SearchConditions event,
    Emitter<ConditionState> emit,
  ) async {
    try {
      // Get the full list first
      final allConditions = await _repository.getAllConditions();

      // Filter based on the query
      final filtered =
          allConditions.where((condition) {
            final query = event.query.toLowerCase();
            final nameMatches = condition.name.toLowerCase().contains(query);
            // We match by name for now, but you could add body system filtering too!
            return nameMatches;
          }).toList();

      emit(ConditionLoaded(filtered, searchQuery: event.query));
    } catch (e) {
      emit(ConditionError("Search failed: $e"));
    }
  }

  /// Simple logic to refresh everything
  Future<void> _onRefreshConditions(
    RefreshConditions event,
    Emitter<ConditionState> emit,
  ) async {
    await _onLoadConditions(LoadConditions(), emit);
  }
}
