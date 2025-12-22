import 'package:equatable/equatable.dart';

/// Events are just "Orders" that the UI sends to the BLoC.
/// They tell the BLoC: "Hey, something happened!"
abstract class HerbEvent extends Equatable {
  const HerbEvent();

  @override
  List<Object?> get props => [];
}

/// This event tells the BLoC: "Please go get all the herbs from the database."
/// We call this when the screen first opens.
class LoadHerbs extends HerbEvent {}

/// This event tells the BLoC: "The user is typing in the search bar,
/// please filter the herbs using this text."
class SearchHerbs extends HerbEvent {
  final String query;

  const SearchHerbs(this.query);

  @override
  List<Object?> get props => [query];
}

/// This event tells the BLoC: "A herb was added or updated,
/// please fetch the latest data so we can see the changes."
class RefreshHerbs extends HerbEvent {}
