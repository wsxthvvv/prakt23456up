import '../models/confectioner_query.dart';
import '../models/customer_query.dart';
import '../models/flavor_query.dart';
import '../models/product_query.dart';
import '../models/workshop_query.dart';

ProductQuery productQueryFromUri(Map<String, String> params) {
  final sortRaw = params['sort'];
  var sortField = 'name';
  var sortAscending = true;
  if (sortRaw != null && sortRaw.contains(',')) {
    final parts = sortRaw.split(',');
    sortField = parts[0];
    sortAscending = parts.length < 2 || parts[1] != 'desc';
  } else if (sortRaw != null) {
    sortField = sortRaw;
  }

  return ProductQuery(
    search: params['search'] ?? '',
    flavorTagId: _intOrNull(params['flavorId']),
    categoryId: _intOrNull(params['categoryId']),
    yearFrom: _intOrNull(params['yearFrom']),
    yearTo: _intOrNull(params['yearTo']),
    sortField: sortField,
    sortAscending: sortAscending,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == '1',
  );
}

String productQueryToLocation(ProductQuery q) {
  final buffer = StringBuffer('/products');
  final pairs = <String, String>{};

  if (q.search.isNotEmpty) pairs['search'] = q.search;
  if (q.flavorTagId != null) pairs['flavorId'] = '${q.flavorTagId}';
  if (q.categoryId != null) pairs['categoryId'] = '${q.categoryId}';
  if (q.yearFrom != null) pairs['yearFrom'] = '${q.yearFrom}';
  if (q.yearTo != null) pairs['yearTo'] = '${q.yearTo}';
  pairs['sort'] = q.sortAscending ? q.sortField : '${q.sortField},desc';
  if (q.page != 1) pairs['page'] = '${q.page}';
  if (q.size != 10) pairs['size'] = '${q.size}';
  if (q.includeDeleted) pairs['includeDeleted'] = '1';

  if (pairs.isEmpty) return buffer.toString();
  buffer.write('?');
  buffer.write(
    pairs.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'),
  );
  return buffer.toString();
}

ConfectionerQuery confectionerQueryFromUri(Map<String, String> params) {
  final sortRaw = params['sort'];
  var sortField = 'lastName';
  var sortAscending = true;
  if (sortRaw != null && sortRaw.contains(',')) {
    final parts = sortRaw.split(',');
    sortField = parts[0];
    sortAscending = parts.length < 2 || parts[1] != 'desc';
  } else if (sortRaw != null) {
    sortField = sortRaw;
  }

  return ConfectionerQuery(
    search: params['search'] ?? '',
    country: params['country'],
    specialty: params['specialty'],
    sortField: sortField,
    sortAscending: sortAscending,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == '1',
  );
}

String confectionerQueryToLocation(ConfectionerQuery q) {
  final buffer = StringBuffer('/confectioners');
  final pairs = <String, String>{};

  if (q.search.isNotEmpty) pairs['search'] = q.search;
  if (q.country != null && q.country!.isNotEmpty) pairs['country'] = q.country!;
  if (q.specialty != null && q.specialty!.isNotEmpty) pairs['specialty'] = q.specialty!;
  pairs['sort'] = q.sortAscending ? q.sortField : '${q.sortField},desc';
  if (q.page != 1) pairs['page'] = '${q.page}';
  if (q.size != 10) pairs['size'] = '${q.size}';
  if (q.includeDeleted) pairs['includeDeleted'] = '1';

  if (pairs.isEmpty) return buffer.toString();
  buffer.write('?');
  buffer.write(
    pairs.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&'),
  );
  return buffer.toString();
}

int? _intOrNull(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
}

(String, bool) _parseSort(String? raw, String fallback) {
  if (raw == null || raw.isEmpty) return (fallback, true);
  if (raw.contains(',')) {
    final parts = raw.split(',');
    return (parts[0], parts.length < 2 || parts[1] != 'desc');
  }
  return (raw, true);
}

String _location(String path, Map<String, String> pairs) {
  if (pairs.isEmpty) return path;
  final query = pairs.entries
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');
  return '$path?$query';
}

void _putSort(Map<String, String> pairs, String field, bool ascending) {
  pairs['sort'] = ascending ? field : '$field,desc';
}

FlavorQuery flavorQueryFromUri(Map<String, String> params) {
  final sort = _parseSort(params['sort'], 'name');
  return FlavorQuery(
    search: params['search'] ?? '',
    intensity: _intOrNull(params['intensity']),
    sortField: sort.$1,
    sortAscending: sort.$2,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == '1',
  );
}

String flavorQueryToLocation(FlavorQuery q) {
  final pairs = <String, String>{};
  if (q.search.isNotEmpty) pairs['search'] = q.search;
  if (q.intensity != null) pairs['intensity'] = '${q.intensity}';
  _putSort(pairs, q.sortField, q.sortAscending);
  if (q.page != 1) pairs['page'] = '${q.page}';
  if (q.size != 10) pairs['size'] = '${q.size}';
  if (q.includeDeleted) pairs['includeDeleted'] = '1';
  return _location('/flavors', pairs);
}

WorkshopQuery workshopQueryFromUri(Map<String, String> params) {
  final sort = _parseSort(params['sort'], 'name');
  return WorkshopQuery(
    search: params['search'] ?? '',
    city: params['city'],
    sortField: sort.$1,
    sortAscending: sort.$2,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == '1',
  );
}

String workshopQueryToLocation(WorkshopQuery q) {
  final pairs = <String, String>{};
  if (q.search.isNotEmpty) pairs['search'] = q.search;
  if (q.city != null && q.city!.isNotEmpty) pairs['city'] = q.city!;
  _putSort(pairs, q.sortField, q.sortAscending);
  if (q.page != 1) pairs['page'] = '${q.page}';
  if (q.size != 10) pairs['size'] = '${q.size}';
  if (q.includeDeleted) pairs['includeDeleted'] = '1';
  return _location('/workshops', pairs);
}

CustomerQuery customerQueryFromUri(Map<String, String> params) {
  final sort = _parseSort(params['sort'], 'lastName');
  bool? cardActive;
  if (params['cardActive'] == '1') cardActive = true;
  if (params['cardActive'] == '0') cardActive = false;
  return CustomerQuery(
    search: params['search'] ?? '',
    cardActive: cardActive,
    sortField: sort.$1,
    sortAscending: sort.$2,
    page: int.tryParse(params['page'] ?? '') ?? 1,
    size: int.tryParse(params['size'] ?? '') ?? 10,
    includeDeleted: params['includeDeleted'] == '1',
  );
}

String customerQueryToLocation(CustomerQuery q) {
  final pairs = <String, String>{};
  if (q.search.isNotEmpty) pairs['search'] = q.search;
  if (q.cardActive != null) pairs['cardActive'] = q.cardActive! ? '1' : '0';
  _putSort(pairs, q.sortField, q.sortAscending);
  if (q.page != 1) pairs['page'] = '${q.page}';
  if (q.size != 10) pairs['size'] = '${q.size}';
  if (q.includeDeleted) pairs['includeDeleted'] = '1';
  return _location('/customers', pairs);
}
