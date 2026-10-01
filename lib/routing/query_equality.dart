import '../models/confectioner_query.dart';
import '../models/customer_query.dart';
import '../models/flavor_query.dart';
import '../models/product_query.dart';
import '../models/workshop_query.dart';

bool productQueriesEqual(ProductQuery a, ProductQuery b) {
  return a.search == b.search &&
      a.flavorTagId == b.flavorTagId &&
      a.categoryId == b.categoryId &&
      a.yearFrom == b.yearFrom &&
      a.yearTo == b.yearTo &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool confectionerQueriesEqual(ConfectionerQuery a, ConfectionerQuery b) {
  return a.search == b.search &&
      a.country == b.country &&
      a.specialty == b.specialty &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool flavorQueriesEqual(FlavorQuery a, FlavorQuery b) {
  return a.search == b.search &&
      a.intensity == b.intensity &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool workshopQueriesEqual(WorkshopQuery a, WorkshopQuery b) {
  return a.search == b.search &&
      a.city == b.city &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}

bool customerQueriesEqual(CustomerQuery a, CustomerQuery b) {
  return a.search == b.search &&
      a.cardActive == b.cardActive &&
      a.sortField == b.sortField &&
      a.sortAscending == b.sortAscending &&
      a.page == b.page &&
      a.size == b.size &&
      a.includeDeleted == b.includeDeleted;
}
