import '../../domain/entities/remedy.dart';

/// Base state for the Remedy feature.
///
/// Every state emitted by RemedyCubit extends RemedyState.
abstract class RemedyState {}

// ------------------------------------------------------------
// INITIAL STATE
// ------------------------------------------------------------
/// The first state of the Cubit.
///
/// Nothing has happened yet.
class RemedyInitial extends RemedyState {}

// ------------------------------------------------------------
// LOADING STATE
// ------------------------------------------------------------
/// The Cubit is currently fetching or processing remedies.
class RemedyLoading extends RemedyState {}

// ------------------------------------------------------------
// LOADED STATE
// ------------------------------------------------------------
/// Contains the remedies that should currently be displayed.
///
/// Notice that we use:
///
///     List<Remedy>
///
/// NOT:
///
///     List<RemedyModel>
///
/// because the presentation layer works with DOMAIN ENTITIES.
class RemedyLoaded extends RemedyState {
  final List<Remedy> remedies;

  /// The current search text.
  ///
  /// This allows the UI to know whether an empty list means:
  ///
  /// "There are no remedies"
  ///
  /// or:
  ///
  /// "There are no remedies matching this search."
  final String searchQuery;

  /// The currently applied condition filter ID (if any).
  final String? filteredConditionId;

  RemedyLoaded(
    this.remedies, {
    this.searchQuery = '',
    this.filteredConditionId,
  });
}

// ------------------------------------------------------------
// ERROR STATE
// ------------------------------------------------------------
/// Something went wrong while performing an operation.
class RemedyError extends RemedyState {
  final String message;

  RemedyError(this.message);
}

// ------------------------------------------------------------
// OPERATION SUCCESS STATE
// ------------------------------------------------------------
/// Used after an operation such as:
///
/// - Creating a remedy
/// - Updating a remedy
/// - Deleting a remedy
/// - Approving a remedy
///
/// succeeds.
///
/// The UI can listen to this state and display a SnackBar.
class RemedyOperationSuccess extends RemedyState {
  final String message;

  RemedyOperationSuccess(this.message);
}
