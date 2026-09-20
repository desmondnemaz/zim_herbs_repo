import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/remedy.dart';
import '../../domain/repositories/remedy_repository.dart';
import '../../../conditions/domain/entities/condition.dart';
import '../../../conditions/domain/repositories/condition_repository.dart';
import '../../../herbs/domain/entities/herb.dart';
import '../../../herbs/domain/repositories/herb_repository.dart';

// ============================================================
// STATES
// ============================================================

enum RemedyFormStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  error,
}

class RemedyHerbRow extends Equatable {
  final Herb? selectedHerb;
  final String quantity;
  final String unit;
  final String preparation;

  const RemedyHerbRow({
    this.selectedHerb,
    this.quantity = '',
    this.unit = '',
    this.preparation = '',
  });

  RemedyHerbRow copyWith({
    Herb? selectedHerb,
    String? quantity,
    String? unit,
    String? preparation,
  }) {
    return RemedyHerbRow(
      selectedHerb: selectedHerb ?? this.selectedHerb,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      preparation: preparation ?? this.preparation,
    );
  }

  @override
  List<Object?> get props => [selectedHerb, quantity, unit, preparation];
}

class RemedyFormState extends Equatable {
  final RemedyFormStatus status;
  final List<Condition> conditions;
  final List<Herb> availableHerbs;
  final List<RemedyHerbRow> herbRows;
  final String? errorMessage;

  const RemedyFormState({
    this.status = RemedyFormStatus.initial,
    this.conditions = const [],
    this.availableHerbs = const [],
    this.herbRows = const [],
    this.errorMessage,
  });

  RemedyFormState copyWith({
    RemedyFormStatus? status,
    List<Condition>? conditions,
    List<Herb>? availableHerbs,
    List<RemedyHerbRow>? herbRows,
    String? errorMessage,
  }) {
    return RemedyFormState(
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

class RemedyFormCubit extends Cubit<RemedyFormState> {
  final HerbRepository _herbRepository;
  final RemedyRepository _remedyRepository;
  final ConditionRepository _conditionRepository;

  RemedyFormCubit({
    required HerbRepository herbRepository,
    required RemedyRepository remedyRepository,
    required ConditionRepository conditionRepository,
  })  : _herbRepository = herbRepository,
        _remedyRepository = remedyRepository,
        _conditionRepository = conditionRepository,
        super(const RemedyFormState());

  /// Load necessary form resources (all conditions and herbs),
  /// and parse the initial remedy's herbs if editing.
  Future<void> loadFormResources(Remedy? remedy) async {
    emit(state.copyWith(status: RemedyFormStatus.loading));
    try {
      final results = await Future.wait([
        _conditionRepository.getAllConditions(),
        _herbRepository.getAllHerbs(),
      ]);

      final conditions = results[0] as List<Condition>;
      final herbs = results[1] as List<Herb>;

      final List<RemedyHerbRow> herbRows = [];
      if (remedy != null) {
        for (var rh in remedy.remedyHerbs) {
          Herb? selectedHerb;
          try {
            selectedHerb = herbs.firstWhere((h) => h.id == rh.herbId);
          } catch (_) {}

          herbRows.add(
            RemedyHerbRow(
              selectedHerb: selectedHerb,
              quantity: rh.quantity ?? '',
              unit: rh.unit ?? '',
              preparation: rh.preparation ?? '',
            ),
          );
        }
      }

      if (herbRows.isEmpty) {
        herbRows.add(const RemedyHerbRow());
      }

      emit(
        state.copyWith(
          status: RemedyFormStatus.loaded,
          conditions: conditions,
          availableHerbs: herbs,
          herbRows: herbRows,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RemedyFormStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// Add a new empty row for selecting a herb and its options.
  void addHerbRow() {
    final updatedRows = List<RemedyHerbRow>.from(state.herbRows)
      ..add(const RemedyHerbRow());
    emit(state.copyWith(herbRows: updatedRows));
  }

  /// Remove a herb row at the given index.
  void removeHerbRow(int index) {
    final updatedRows = List<RemedyHerbRow>.from(state.herbRows);
    if (index >= 0 && index < updatedRows.length) {
      updatedRows.removeAt(index);
      emit(state.copyWith(herbRows: updatedRows));
    }
  }

  /// Update the selected herb for a specific row.
  void selectHerb(int index, Herb herb) {
    if (index < 0 || index >= state.herbRows.length) return;

    final updatedRows = List<RemedyHerbRow>.from(state.herbRows);
    final currentRow = updatedRows[index];

    updatedRows[index] = currentRow.copyWith(selectedHerb: herb);

    emit(state.copyWith(herbRows: updatedRows));
  }

  /// Submit the completed remedy form to create/update the database.
  Future<void> submitRemedy(Remedy remedy) async {
    emit(state.copyWith(status: RemedyFormStatus.submitting));
    try {
      if (remedy.id.isEmpty) {
        await _remedyRepository.createRemedy(remedy);
      } else {
        await _remedyRepository.updateRemedy(remedy);
      }
      emit(state.copyWith(status: RemedyFormStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: RemedyFormStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
