import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../../conditions/domain/entities/condition.dart';
import '../../../conditions/domain/repositories/condition_repository.dart';
import '../../../herbs/domain/entities/herb.dart';
import '../../../herbs/domain/repositories/herb_repository.dart';

// ============================================================
// STATES
// ============================================================

enum TreatmentFormStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  error,
}

class TreatmentHerbRow extends Equatable {
  final Herb? selectedHerb;
  final String quantity;
  final String unit;
  final String preparation;

  const TreatmentHerbRow({
    this.selectedHerb,
    this.quantity = '',
    this.unit = '',
    this.preparation = '',
  });

  TreatmentHerbRow copyWith({
    Herb? selectedHerb,
    String? quantity,
    String? unit,
    String? preparation,
  }) {
    return TreatmentHerbRow(
      selectedHerb: selectedHerb ?? this.selectedHerb,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      preparation: preparation ?? this.preparation,
    );
  }

  @override
  List<Object?> get props => [selectedHerb, quantity, unit, preparation];
}

class TreatmentFormState extends Equatable {
  final TreatmentFormStatus status;
  final List<Condition> conditions;
  final List<Herb> availableHerbs;
  final List<TreatmentHerbRow> herbRows;
  final String? errorMessage;

  const TreatmentFormState({
    this.status = TreatmentFormStatus.initial,
    this.conditions = const [],
    this.availableHerbs = const [],
    this.herbRows = const [],
    this.errorMessage,
  });

  TreatmentFormState copyWith({
    TreatmentFormStatus? status,
    List<Condition>? conditions,
    List<Herb>? availableHerbs,
    List<TreatmentHerbRow>? herbRows,
    String? errorMessage,
  }) {
    return TreatmentFormState(
      status: status ?? this.status,
      conditions: conditions ?? this.conditions,
      availableHerbs: availableHerbs ?? this.availableHerbs,
      herbRows: herbRows ?? this.herbRows,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        conditions,
        availableHerbs,
        herbRows,
        errorMessage,
      ];
}

// ============================================================
// CUBIT
// ============================================================

class TreatmentFormCubit extends Cubit<TreatmentFormState> {
  final HerbRepository _herbRepository;
  final TreatmentRepository _treatmentRepository;
  final ConditionRepository _conditionRepository;

  TreatmentFormCubit({
    required HerbRepository herbRepository,
    required TreatmentRepository treatmentRepository,
    required ConditionRepository conditionRepository,
  })  : _herbRepository = herbRepository,
        _treatmentRepository = treatmentRepository,
        _conditionRepository = conditionRepository,
        super(const TreatmentFormState());

  /// Load necessary form resources (all conditions and herbs),
  /// and parse the initial treatment's herbs if editing.
  Future<void> loadFormResources(Treatment? treatment) async {
    emit(state.copyWith(status: TreatmentFormStatus.loading));
    try {
      final results = await Future.wait([
        _conditionRepository.getAllConditions(),
        _herbRepository.getAllHerbs(),
      ]);

      final conditions = results[0] as List<Condition>;
      final herbs = results[1] as List<Herb>;

      final List<TreatmentHerbRow> herbRows = [];
      if (treatment != null) {
        for (var th in treatment.treatmentHerbs) {
          Herb? selectedHerb;
          try {
            selectedHerb = herbs.firstWhere((h) => h.id == th.herbId);
          } catch (_) {}

          herbRows.add(
            TreatmentHerbRow(
              selectedHerb: selectedHerb,
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
          conditions: conditions,
          availableHerbs: herbs,
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

  /// Add a new empty row for selecting a herb and its options.
  void addHerbRow() {
    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows)
      ..add(const TreatmentHerbRow());
    emit(state.copyWith(herbRows: updatedRows));
  }

  /// Remove a herb row at the given index.
  void removeHerbRow(int index) {
    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows);
    if (index >= 0 && index < updatedRows.length) {
      updatedRows.removeAt(index);
      emit(state.copyWith(herbRows: updatedRows));
    }
  }

  /// Update the selected herb for a specific row.
  void selectHerb(int index, Herb herb) {
    if (index < 0 || index >= state.herbRows.length) return;

    final updatedRows = List<TreatmentHerbRow>.from(state.herbRows);
    final currentRow = updatedRows[index];

    updatedRows[index] = currentRow.copyWith(selectedHerb: herb);

    emit(state.copyWith(herbRows: updatedRows));
  }

  /// Submit the completed treatment form to create/update the database.
  Future<void> submitTreatment(Treatment treatment) async {
    emit(state.copyWith(status: TreatmentFormStatus.submitting));
    try {
      if (treatment.id.isEmpty) {
        await _treatmentRepository.createTreatment(treatment);
      } else {
        await _treatmentRepository.updateTreatment(treatment);
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
