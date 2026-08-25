import '../../domain/entities/treatment.dart';

/// Base state for the Treatment feature.
///
/// Every state emitted by TreatmentCubit extends TreatmentState.
abstract class TreatmentState {}

// ------------------------------------------------------------
// INITIAL STATE
// ------------------------------------------------------------
/// The first state of the Cubit.
///
/// Nothing has happened yet.
class TreatmentInitial extends TreatmentState {}

// ------------------------------------------------------------
// LOADING STATE
// ------------------------------------------------------------
/// The Cubit is currently fetching or processing treatments.
class TreatmentLoading extends TreatmentState {}

// ------------------------------------------------------------
// LOADED STATE
// ------------------------------------------------------------
/// Contains the treatments that should currently be displayed.
///
/// Notice that we use:
///
///     List<Treatment>
///
/// NOT:
///
///     List<TreatmentModel>
///
/// because the presentation layer works with DOMAIN ENTITIES.
class TreatmentLoaded extends TreatmentState {
  final List<Treatment> treatments;

  /// The current search text.
  ///
  /// This allows the UI to know whether an empty list means:
  ///
  /// "There are no treatments"
  ///
  /// or:
  ///
  /// "There are no treatments matching this search."
  final String searchQuery;

  /// The currently applied condition filter ID (if any).
  final String? filteredConditionId;

  TreatmentLoaded(
    this.treatments, {
    this.searchQuery = '',
    this.filteredConditionId,
  });
}

// ------------------------------------------------------------
// ERROR STATE
// ------------------------------------------------------------
/// Something went wrong while performing an operation.
class TreatmentError extends TreatmentState {
  final String message;

  TreatmentError(this.message);
}

// ------------------------------------------------------------
// OPERATION SUCCESS STATE
// ------------------------------------------------------------
/// Used after an operation such as:
///
/// - Creating a treatment
/// - Updating a treatment
/// - Deleting a treatment
/// - Approving a treatment
///
/// succeeds.
///
/// The UI can listen to this state and display a SnackBar.
class TreatmentOperationSuccess extends TreatmentState {
  final String message;

  TreatmentOperationSuccess(this.message);
}
