import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';

/// States are like "Snapshots" of what the UI should look like right now.
/// The BLoC sends these back to the UI.
abstract class HerbState extends Equatable {
  const HerbState();

  @override
  List<Object?> get props => [];
}

/// 1. Initial State: The screen just loaded, nothing has happened yet.
class HerbInitial extends HerbState {}

/// 2. Loading State: We are currently talking to Supabase. Show a spinner!
class HerbLoading extends HerbState {}

/// 3. Loaded State: Success! We have the list of herbs to show.
class HerbLoaded extends HerbState {
  final List<HerbModel> herbs;
  // We keep the search query here so the UI knows what's being filtered
  final String searchQuery;

  const HerbLoaded(this.herbs, {this.searchQuery = ""});

  @override
  List<Object?> get props => [herbs, searchQuery];
}

/// 4. Error State: Oh no! Something went wrong (e.g., no internet).
class HerbError extends HerbState {
  final String message;

  const HerbError(this.message);

  @override
  List<Object?> get props => [message];
}
