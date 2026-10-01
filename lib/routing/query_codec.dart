import '../models/confectioner_query.dart';
import '../models/product_query.dart';

/// Параметры genreId и publisherId — как в задании (жанр и издательство);
/// для кондитерской это вкус и категория изделия.
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

  final genreId = _intOrNull(params['genreId'] ?? params['flavorTagId']);
  final publisherId = _intOrNull(params['publisherId'] ?? params['categoryId']);

  return ProductQuery(
    search: params['search'] ?? '',
    flavorTagId: genreId,
    categoryId: publisherId,
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
  if (q.flavorTagId != null) pairs['genreId'] = '${q.flavorTagId}';
  if (q.categoryId != null) pairs['publisherId'] = '${q.categoryId}';
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
