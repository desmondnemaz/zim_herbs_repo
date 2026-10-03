import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
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
  final Failure? failure;

  const RemedyDetailError(this.message, {this.failure});

  @override
  List<Object?> get props => [message, failure];
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
        emit(const RemedyDetailError(
          'Remedy not found',
          failure: Failure(
            title: 'Remedy Not Found',
            message: 'The requested remedy details could not be found.',
            type: FailureType.notFound,
          ),
        ));
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(RemedyDetailError(failure.message, failure: failure));
    }
  }
}
