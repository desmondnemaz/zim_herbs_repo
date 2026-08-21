import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/entities/condition.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/repositories/condition_repository.dart';
import 'package:zim_herbs_repo/features/repository/conditions/data/models/condition_model.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/models/herb_model.dart';
import 'package:zim_herbs_repo/features/repository/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/repository/treatments/data/treatment_repository.dart';

part 'treatment_form_event.dart';
part 'treatment_form_state.dart';

class TreatmentFormBloc extends Bloc<TreatmentFormEvent, TreatmentFormState> {
  final HerbRepository _herbRepository;
  final TreatmentRepository _treatmentRepository;
  final ConditionRepository _conditionRepository;

  TreatmentFormBloc({
    required HerbRepository herbRepository,
    required TreatmentRepository treatmentRepository,
    required ConditionRepository conditionRepository,
  })  : _herbRepository = herbRepository,
        _treatmentRepository = treatmentRepository,
        _conditionRepository = conditionRepository,
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
        _conditionRepository.getAllConditions(),
        _herbRepository.getAllHerbs(),
      ]);

      final conditions = results[0] as List<Condition>;
      final conditionModels =
          conditions.map((c) => ConditionModel.fromEntity(c)).toList();
      final herbs = results[1] as List<Herb>;
      final availableHerbModels =
          herbs.map((h) => HerbModel.fromEntity(h)).toList();

      final List<TreatmentHerbRow> herbRows = [];
      if (event.treatment != null) {
        for (var th in event.treatment!.treatmentHerbs) {
          herbRows.add(
            TreatmentHerbRow(
              selectedHerb: th.herb,
              quantity: th.quantity ?? '',
              unit: th.unit ?? '',
              preparation: th.preparation ?? '',
            ),
          );
        }
      }

      if (herbRows.isEmpty) {
        herbRows.add(const TreatmentHerbRow());
      }

      emit(
        state.copyWith(
          status: TreatmentFormStatus.loaded,
          conditions: conditionModels,
          availableHerbs: availableHerbModels,
          herbRows: herbRows,
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
      if (event.treatment.id.isEmpty) {
        await _treatmentRepository.createTreatment(
          event.treatment,
          event.treatment.treatmentHerbs,
        );
      } else {
        await _treatmentRepository.updateTreatment(event.treatment);
      }

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
