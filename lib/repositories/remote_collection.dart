import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../core/pb_links.dart';
import '../models/page_result.dart';

class RemoteCollection<T> {
  RemoteCollection({
    required this.dio,
    required this.resource,
    required this.decode,
    required this.encode,
    required this.idOf,
    this.links,
    this.hints = const PbHints(),
    this.relations = const {},
    this.softDeletes = true,
  });

  final Dio dio;
  final String resource;
  final T Function(Map<String, dynamic>) decode;
  final Map<String, dynamic> Function(T item) encode;
  final int Function(T item) idOf;
  final PbLinks? links;
  final PbHints hints;
  final Map<String, PbRelation> relations;
  final bool softDeletes;

  final List<T> cache = [];
  CancelToken? _listToken;

  PbLinks get _links => links ?? PbLinks.shared;

  List<T> get all => List.unmodifiable(cache);

  String get expand {
    final names = <String>{
      for (final relation in relations.values) relation.field,
      ...hints.expand,
    };
    return names.join(',');
  }

  Future<void> warm() => _reload();

  Future<PageResult<T>> find(Map<String, dynamic> query) {
    _listToken?.cancel('устаревший запрос');
    final token = CancelToken();
    _listToken = token;
    return _get(query, cancelToken: token);
  }

  Future<T?> findById(int id) => guard(() async {
    final pb = _links.pbId(resource, id);
    try {
      if (pb != null) {
        final response = await dio.get(
          '/collections/$resource/records/$pb',
          queryParameters: {if (expand.isNotEmpty) 'expand': expand},
        );
        return _take(response.data);
      }
    } on DioException catch (error) {
      if (mapDioError(error) is! NotFoundException) rethrow;
    }
    final page = await _get({
      'filter': 'code = $id',
      'page': 1,
      'size': 1,
      'includeDeleted': true,
    });
    if (page.items.isEmpty) return null;
    return page.items.first;
  });

  Future<T> create(T item) => guard(() async {
    final response = await dio.post(
      '/collections/$resource/records',
      queryParameters: {if (expand.isNotEmpty) 'expand': expand},
      data: _body(item, creating: true),
    );
    final created = _take(response.data);
    cache.add(created);
    return created;
  });

  Future<T> update(T item) => guard(() async {
    final pb = _requirePb(idOf(item));
    final response = await dio.patch(
      '/collections/$resource/records/$pb',
      queryParameters: {if (expand.isNotEmpty) 'expand': expand},
      data: _body(item, creating: false),
    );
    final saved = _take(response.data);
    final index = cache.indexWhere((row) => idOf(row) == idOf(saved));
    if (index >= 0) {
      cache[index] = saved;
    } else {
      cache.add(saved);
    }
    return saved;
  });

  Future<void> softDelete(int id) => guard(() async {
    final pb = _requirePb(id);
    await dio.patch('/collections/$resource/records/$pb', data: {'deleted': true});
    await _reload();
  });

  Future<void> hardDelete(int id) => guard(() async {
    final pb = await _pbFor(id);
    await dio.delete('/collections/$resource/records/$pb');
    cache.removeWhere((item) => idOf(item) == id);
    _links.remember(resource, id, '');
  });

  Future<void> restore(int id) => guard(() async {
    final pb = _requirePb(id);
    final response = await dio.patch(
      '/collections/$resource/records/$pb',
      queryParameters: {if (expand.isNotEmpty) 'expand': expand},
      data: {'deleted': false},
    );
    final saved = _take(response.data);
    final index = cache.indexWhere((row) => idOf(row) == id);
    if (index >= 0) {
      cache[index] = saved;
    } else {
      cache.add(saved);
    }
  });

  Future<int> deleteMany(List<int> ids) => guard(() async {
    for (final id in ids) {
      final pb = _links.pbId(resource, id);
      if (pb == null) continue;
      await dio.patch(
        '/collections/$resource/records/$pb',
        data: {'deleted': true},
      );
    }
    await _reload();
    return ids.length;
  });

  Map<String, dynamic> _body(T item, {required bool creating}) {
    final raw = encode(item);
    final body = <String, dynamic>{};
    for (final entry in raw.entries) {
      final relation = relations[entry.key];
      if (relation == null) {
        body[entry.key] = entry.value;
        continue;
      }
      if (relation.many) {
        final codes = entry.value is List ? entry.value as List : const [];
        body[relation.field] = [
          for (final code in codes)
            if (_links.pbId(relation.collection, jsonInt(code)) != null)
              _links.pbId(relation.collection, jsonInt(code)),
        ];
      } else {
        final pb = _links.pbId(relation.collection, jsonInt(entry.value));
        if (pb != null) body[relation.field] = pb;
      }
    }
    body.remove('loyaltyCard');
    if (creating && body['code'] == null) {
      final code = idOf(item);
      body['code'] = code > 0 ? code : _links.nextCode(resource);
    }
    if (!creating) body.remove('code');
    return body;
  }

  Future<String> _pbFor(int code) async {
    final known = _links.pbId(resource, code);
    if (known != null && known.isNotEmpty) return known;
    final response = await dio.get(
      '/collections/$resource/records',
      queryParameters: {'filter': 'code = $code', 'perPage': 1, 'page': 1},
    );
    final data = _asMap(response.data);
    final items = data['items'];
    if (items is List && items.isNotEmpty && items.first is Map) {
      final row = Map<String, dynamic>.from(items.first as Map);
      final pb = jsonString(row['id']);
      _links.remember(resource, code, pb);
      return pb;
    }
    throw const NotFoundException('Запись не найдена.');
  }

  String _requirePb(int code) {
    final pb = _links.pbId(resource, code);
    if (pb == null || pb.isEmpty) {
      throw const NotFoundException('Запись не найдена.');
    }
    return pb;
  }

  T _take(dynamic data) {
    final presented = _present(_asMap(data));
    return decode(presented);
  }

  Map<String, dynamic> _present(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final code = jsonInt(raw['code']);
    out['id'] = code;
    if (raw['deleted'] == true) {
      out['deletedAt'] = raw['updated'] ?? DateTime.now().toIso8601String();
    } else {
      out['deletedAt'] = null;
    }
    final pbId = jsonString(raw['id']);
    out['pbId'] = pbId;
    _links.remember(resource, code, pbId);
    final expanded = raw['expand'];
    final expandMap = expanded is Map
        ? Map<String, dynamic>.from(expanded)
        : const <String, dynamic>{};
    for (final entry in relations.entries) {
      final relation = entry.value;
      final value = expandMap[relation.field];
      if (relation.many) {
        final rows = value is List ? value : const [];
        out[entry.key] = [
          for (final row in rows)
            if (row is Map) jsonInt(row['code']),
        ];
        if (value is List) {
          for (final row in value) {
            if (row is Map) {
              _links.remember(
                relation.collection,
                jsonInt(row['code']),
                jsonString(row['id']),
              );
            }
          }
        }
      } else if (value is Map) {
        out[entry.key] = jsonInt(value['code']);
        _links.remember(
          relation.collection,
          jsonInt(value['code']),
          jsonString(value['id']),
        );
      } else {
        out[entry.key] = relation.many ? <int>[] : 0;
      }
    }
    return out;
  }

  Future<PageResult<T>> _get(
    Map<String, dynamic> query, {
    CancelToken? cancelToken,
  }) => guard(() async {
    final response = await dio.get(
      '/collections/$resource/records',
      queryParameters: _query(query),
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    final items = [
      for (final item in (data['items'] as List? ?? const []))
        if (item is Map) _take(Map<String, dynamic>.from(item)),
    ];
    return PageResult(
      items: items,
      page: jsonInt(data['page'], 1),
      size: jsonInt(data['perPage'], jsonInt(query['size'], 10)),
      total: jsonInt(data['totalItems']),
    );
  });

  Map<String, dynamic> _query(Map<String, dynamic> query) {
    final parts = <String>[];
    final includeDeleted = query['includeDeleted'] == true;
    if (softDeletes && !includeDeleted) parts.add('deleted = false');
    final extra = query['filter'];
    if (extra is String && extra.isNotEmpty) parts.add('($extra)');
    final search = jsonString(query['search']).trim();
    if (search.isNotEmpty && hints.searchFields.isNotEmpty) {
      final quoted = pbQuote(search);
      parts.add(
        '(${hints.searchFields.map((field) => '$field ~ $quoted').join(' || ')})',
      );
    }
    for (final entry in hints.equals.entries) {
      final value = query[entry.key];
      if (value == null || '$value'.isEmpty) continue;
      final rendered = value is num ? '$value' : pbQuote(value);
      parts.add('${entry.value} = $rendered');
    }
    for (final entry in hints.relations.entries) {
      final code = query[entry.key];
      if (code == null) continue;
      final pb = _links.pbId(entry.value.collection, jsonInt(code));
      if (pb == null) {
        parts.add('code = 0');
        continue;
      }
      final quoted = pbQuote(pb);
      parts.add(
        entry.value.many
            ? '${entry.value.field}.id ?= $quoted'
            : '${entry.value.field} = $quoted',
      );
    }
    for (final entry in hints.minimum.entries) {
      final value = query[entry.key];
      if (value is num) parts.add('${entry.value} >= $value');
    }
    for (final entry in hints.maximum.entries) {
      final value = query[entry.key];
      if (value is num) parts.add('${entry.value} <= $value');
    }
    final sortRaw = jsonString(query['sort']);
    var sort = 'code';
    if (sortRaw.contains(',')) {
      final bits = sortRaw.split(',');
      sort = bits.length > 1 && bits[1] == 'desc' ? '-${bits[0]}' : bits[0];
    } else if (sortRaw.isNotEmpty) {
      sort = sortRaw;
    }
    return {
      'page': query['page'] ?? 1,
      'perPage': query['size'] ?? 10,
      'sort': sort,
      if (parts.isNotEmpty) 'filter': parts.join(' && '),
      if (expand.isNotEmpty) 'expand': expand,
    };
  }

  Future<void> _reload() async {
    final loaded = <T>[];
    var page = 1;
    while (true) {
      final result = await _get({
        'page': page,
        'size': 100,
        'includeDeleted': true,
        'sort': 'code,asc',
      });
      loaded.addAll(result.items);
      if (loaded.length >= result.total || result.items.isEmpty) break;
      page += 1;
    }
    cache
      ..clear()
      ..addAll(loaded);
  }
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const ServerException('Сервер вернул неожиданный ответ.');
}
