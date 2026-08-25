import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';

// ============================================================
// STATES
// ============================================================

abstract class TreatmentDetailState extends Equatable {
  const TreatmentDetailState();

  @override
  List<Object?> get props => [];
}

class TreatmentDetailInitial extends TreatmentDetailState {}

class TreatmentDetailLoading extends TreatmentDetailState {}

/// Contains the full treatment domain entity for the detail view.
class TreatmentDetailLoaded extends TreatmentDetailState {
  /// Domain entity — no Supabase / model leakage into the UI.
  final Treatment treatment;

  const TreatmentDetailLoaded(this.treatment);

  @override
  List<Object?> get props => [treatment];
}

class TreatmentDetailError extends TreatmentDetailState {
  final String message;

  const TreatmentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// CUBIT
// ============================================================

/// Cubit responsible for loading and displaying a single treatment.
///
/// Uses the DOMAIN TreatmentRepository contract.
class TreatmentDetailCubit extends Cubit<TreatmentDetailState> {
  final TreatmentRepository _repository;

  TreatmentDetailCubit(this._repository) : super(TreatmentDetailInitial());

  Future<void> loadTreatment(String id) async {
    emit(TreatmentDetailLoading());
    try {
      final treatment = await _repository.getTreatmentById(id);
      if (treatment != null) {
        emit(TreatmentDetailLoaded(treatment));
      } else {
        emit(const TreatmentDetailError('Treatment not found'));
      }
    } catch (e) {
      emit(TreatmentDetailError('Failed to load treatment details: $e'));
    }
  }
}
