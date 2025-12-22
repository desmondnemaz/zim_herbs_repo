import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart'; // Keep herb repo for fetching herbs/conditions
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';

part 'treatment_form_event.dart';
part 'treatment_form_state.dart';

class TreatmentFormBloc extends Bloc<TreatmentFormEvent, TreatmentFormState> {
  final HerbRepository _herbRepository;
  final TreatmentRepository _treatmentRepository;

  TreatmentFormBloc({
    required HerbRepository herbRepository,
    required TreatmentRepository treatmentRepository,
  }) : _herbRepository = herbRepository,
       _treatmentRepository = treatmentRepository,
       super(const TreatmentFormState()) {
    on<LoadFormResources>(_onLoadFormResources);
    on<AddHerbRow>(_onAddHerbRow);
    on<RemoveHerbRow>(_onRemoveHerbRow);
    on<HerbSelected>(_onHerbSelected);
    on<SubmitTreatment>(_onSubmitTreatment);
  }

  Future<void> _onLoadFormResources(
    LoadFormResources event,
    Emitter<TreatmentFormState> emit,
  ) async {
    emit(state.copyWith(status: TreatmentFormStatus.loading));
    try {
      final results = await Future.wait([
        _herbRepository.getAllConditions(),
        _herbRepository.getAllHerbs(),
      ]);

      emit(
        state.copyWith(
          status: TreatmentFormStatus.loaded,
          conditions: results[0] as List<ConditionModel>,
          availableHerbs: results[1] as List<HerbModel>,
          herbRows: [const TreatmentHerbRow()],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: TreatmentFormStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onAddHerbRow(AddHerbRow event, Emitter<TreatmentFormState> emit) {
    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows)
      ..add(const TreatmentHerbRow());
    emit(state.copyWith(herbRows: updatedRows));
  }

  void _onRemoveHerbRow(RemoveHerbRow event, Emitter<TreatmentFormState> emit) {
    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows);
    if (event.index >= 0 && event.index < updatedRows.length) {
      updatedRows.removeAt(event.index);
      emit(state.copyWith(herbRows: updatedRows));
    }
  }

  void _onHerbSelected(HerbSelected event, Emitter<TreatmentFormState> emit) {
    if (event.index < 0 || event.index >= state.herbRows.length) return;

    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows);
    final currentRow = updatedRows[event.index];

    updatedRows[event.index] = currentRow.copyWith(selectedHerb: event.herb);

    emit(state.copyWith(herbRows: updatedRows));
  }

  Future<void> _onSubmitTreatment(
    SubmitTreatment event,
    Emitter<TreatmentFormState> emit,
  ) async {
    emit(state.copyWith(status: TreatmentFormStatus.submitting));
    try {
      await _treatmentRepository.createTreatment(
        event.treatment,
        event.treatment.treatmentHerbs,
      );

      emit(state.copyWith(status: TreatmentFormStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: TreatmentFormStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
