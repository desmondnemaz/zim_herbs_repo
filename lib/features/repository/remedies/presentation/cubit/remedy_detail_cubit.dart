import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/remedy.dart';
import '../../domain/repositories/remedy_repository.dart';

// ============================================================
// STATES
// ============================================================

abstract class RemedyDetailState extends Equatable {
  const RemedyDetailState();

  @override
  List<Object?> get props => [];
}

class RemedyDetailInitial extends RemedyDetailState {}

class RemedyDetailLoading extends RemedyDetailState {}

/// Contains the full remedy domain entity for the detail view.
class RemedyDetailLoaded extends RemedyDetailState {
  /// Domain entity — no Supabase / model leakage into the UI.
  final Remedy remedy;

  const RemedyDetailLoaded(this.remedy);

  @override
  List<Object?> get props => [remedy];
}

class RemedyDetailError extends RemedyDetailState {
  final String message;

  const RemedyDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// CUBIT
// ============================================================

/// Cubit responsible for loading and displaying a single remedy.
///
/// Uses the DOMAIN RemedyRepository contract.
class RemedyDetailCubit extends Cubit<RemedyDetailState> {
  final RemedyRepository _repository;

  RemedyDetailCubit(this._repository) : super(RemedyDetailInitial());

  Future<void> loadRemedy(String id) async {
    emit(RemedyDetailLoading());
    try {
      final remedy = await _repository.getRemedyById(id);
      if (remedy != null) {
        emit(RemedyDetailLoaded(remedy));
      } else {
        emit(const RemedyDetailError('Remedy not found'));
      }
    } catch (e) {
      emit(RemedyDetailError('Failed to load remedy details: $e'));
    }
  }
}
