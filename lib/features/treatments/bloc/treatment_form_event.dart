part of 'treatment_form_bloc.dart';

abstract class TreatmentFormEvent extends Equatable {
  const TreatmentFormEvent();

  @override
  List<Object?> get props => [];
}

class LoadFormResources extends TreatmentFormEvent {
  final TreatmentModel? treatment;
  const LoadFormResources({this.treatment});

  @override
  List<Object?> get props => [treatment];
}

class AddHerbRow extends TreatmentFormEvent {}

class RemoveHerbRow extends TreatmentFormEvent {
  final int index;
  const RemoveHerbRow(this.index);

  @override
  List<Object?> get props => [index];
}

class HerbSelected extends TreatmentFormEvent {
  final int index;
  final HerbModel herb;

  const HerbSelected({required this.index, required this.herb});

  @override
  List<Object?> get props => [index, herb];
}

class SubmitTreatment extends TreatmentFormEvent {
  final TreatmentModel treatment;

  const SubmitTreatment(this.treatment);

  @override
  List<Object?> get props => [treatment];
}
