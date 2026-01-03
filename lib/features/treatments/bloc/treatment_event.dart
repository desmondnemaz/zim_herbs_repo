part of 'treatment_bloc.dart';

abstract class TreatmentEvent extends Equatable {
  const TreatmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadTreatments extends TreatmentEvent {}

class SearchTreatments extends TreatmentEvent {
  final String query;
  const SearchTreatments(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTreatmentsByCondition extends TreatmentEvent {
  final String? conditionId; // Null implies "All"
  const FilterTreatmentsByCondition(this.conditionId);

  @override
  List<Object?> get props => [conditionId];
}

class RefreshTreatments extends TreatmentEvent {}
