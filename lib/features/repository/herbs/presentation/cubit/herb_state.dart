import '../../domain/entities/herb.dart';

/// Base state for the Herb feature.
///
/// Every state emitted by HerbCubit extends HerbState.
abstract class HerbState {}

/// ------------------------------------------------------------
/// INITIAL STATE
/// ------------------------------------------------------------
/// The first state of the Cubit.
///
/// Nothing has happened yet.
class HerbInitial extends HerbState {}


/// ------------------------------------------------------------
/// LOADING STATE
/// ------------------------------------------------------------
/// The Cubit is currently fetching or processing herbs.
class HerbLoading extends HerbState {}


/// ------------------------------------------------------------
/// LOADED STATE
/// ------------------------------------------------------------
/// Contains the herbs that should currently be displayed.
///
/// Notice that we use:
///
///     List<Herb>
///
/// NOT:
///
///     List<HerbModel>
///
/// because the presentation layer works with DOMAIN ENTITIES.
class HerbLoaded extends HerbState {
  final List<Herb> herbs;

  /// The current search text.
  ///
  /// This allows the UI to know whether an empty list means:
  ///
  /// "There are no herbs"
  ///
  /// or:
  ///
  /// "There are no herbs matching this search."
  final String searchQuery;

  HerbLoaded(
    this.herbs, {
    this.searchQuery = '',
  });
}


/// ------------------------------------------------------------
/// ERROR STATE
/// ------------------------------------------------------------
/// Something went wrong while performing an operation.
class HerbError extends HerbState {
  final String message;

  HerbError(this.message);
}


/// ------------------------------------------------------------
/// OPERATION SUCCESS STATE
/// ------------------------------------------------------------
/// Used after an operation such as:
///
/// - Creating a herb
/// - Updating a herb
/// - Deleting a herb
///
/// succeeds.
///
/// The UI can listen to this state and display a SnackBar.
class HerbOperationSuccess extends HerbState {
  final String message;

  HerbOperationSuccess(this.message);
}