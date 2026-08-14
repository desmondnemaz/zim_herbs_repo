part of 'treatment_form_bloc.dart';

enum TreatmentFormStatus {
  initial,
  loading,
  loaded,
  submitting,
  success,
  error,
}

class TreatmentFormState extends Equatable {
  final TreatmentFormStatus status;
  final List<ConditionModel> conditions;
  final List<HerbModel> availableHerbs;
  final String? errorMessage;
  final List<TreatmentHerbRow> herbRows;

  const TreatmentFormState({
    this.status = TreatmentFormStatus.initial,
    this.conditions = const [],
    this.availableHerbs = const [],
    this.herbRows = const [],
    this.errorMessage,
  });

  TreatmentFormState copyWith({
    TreatmentFormStatus? status,
    List<ConditionModel>? conditions,
    List<HerbModel>? availableHerbs,
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

class TreatmentHerbRow extends Equatable {
  final HerbModel? selectedHerb;
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
    HerbModel? selectedHerb,
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
