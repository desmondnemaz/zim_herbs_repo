abstract class StoreEvent {}

class FetchProducts extends StoreEvent {
  final String? category;
  FetchProducts({this.category});
}

class SearchProducts extends StoreEvent {
  final String query;
  SearchProducts(this.query);
}
