import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';

part 'treatment_event.dart';
part 'treatment_state.dart';

class TreatmentBloc extends Bloc<TreatmentEvent, TreatmentState> {
  final TreatmentRepository _repository;

  TreatmentBloc(this._repository) : super(TreatmentInitial()) {
    on<LoadTreatments>(_onLoadTreatments);
    on<SearchTreatments>(_onSearchTreatments);
    on<FilterTreatmentsByCondition>(_onFilterTreatmentsByCondition);
    on<RefreshTreatments>(_onRefreshTreatments);
    on<DeleteTreatment>(_onDeleteTreatment);
    on<ApproveTreatment>(_onApproveTreatment);
  }

  Future<void> _onDeleteTreatment(
    DeleteTreatment event,
    Emitter<TreatmentState> emit,
  ) async {
    emit(TreatmentLoading());
    try {
      await _repository.deleteTreatment(event.id);
      emit(const TreatmentOperationSuccess("Treatment deleted successfully"));
      add(RefreshTreatments());
    } catch (e) {
      emit(TreatmentError("Failed to delete treatment: $e"));
    }
  }

  Future<void> _onApproveTreatment(
    ApproveTreatment event,
    Emitter<TreatmentState> emit,
  ) async {
    emit(TreatmentLoading());
    try {
      await _repository.approveTreatment(event.id, approved: event.approved);
      final message =
          event.approved ? "Treatment approved" : "Treatment unapproved";
      emit(TreatmentOperationSuccess(message));
      add(RefreshTreatments());
    } catch (e) {
      emit(TreatmentError("Failed to update approval status: $e"));
    }
  }

  Future<void> _onLoadTreatments(
    LoadTreatments event,
    Emitter<TreatmentState> emit,
  ) async {
    emit(TreatmentLoading());
    try {
      final treatments = await _repository.getAllTreatments();
      emit(TreatmentLoaded(treatments));
    } catch (e) {
      emit(TreatmentError("Failed to load treatments: $e"));
    }
  }

  Future<void> _onSearchTreatments(
    SearchTreatments event,
    Emitter<TreatmentState> emit,
  ) async {
    emit(TreatmentLoading());
    try {
      // If query is empty, load all
      if (event.query.isEmpty) {
        final treatments = await _repository.getAllTreatments();
        emit(TreatmentLoaded(treatments));
      } else {
        final results = await _repository.searchTreatments(event.query);
        emit(TreatmentLoaded(results, searchQuery: event.query));
      }
    } catch (e) {
      emit(TreatmentError("Search failed: $e"));
    }
  }

  Future<void> _onFilterTreatmentsByCondition(
    FilterTreatmentsByCondition event,
    Emitter<TreatmentState> emit,
  ) async {
    emit(TreatmentLoading());
    try {
      if (event.conditionId == null) {
        final treatments = await _repository.getAllTreatments();
        emit(TreatmentLoaded(treatments));
      } else {
        final treatments = await _repository.getTreatmentsByCondition(
          event.conditionId!,
        );
        emit(TreatmentLoaded(treatments));
      }
    } catch (e) {
      emit(TreatmentError("Failed to filter treatments: $e"));
    }
  }

  Future<void> _onRefreshTreatments(
    RefreshTreatments event,
    Emitter<TreatmentState> emit,
  ) async {
    add(LoadTreatments());
  }
}
