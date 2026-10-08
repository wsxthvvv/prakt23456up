import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../models/page_result.dart';

class RemoteCollection<T> {
  RemoteCollection({
    required this.dio,
    required this.resource,
    required this.decode,
    required this.encode,
    required this.idOf,
  });

  final Dio dio;
  final String resource;
  final T Function(Map<String, dynamic>) decode;
  final Map<String, dynamic> Function(T item) encode;
  final int Function(T item) idOf;

  final List<T> cache = [];
  CancelToken? _listToken;

  List<T> get all => List.unmodifiable(cache);

  Future<void> warm() => _reload();

  Future<PageResult<T>> find(Map<String, dynamic> query) {
    _listToken?.cancel('устаревший запрос');
    final token = CancelToken();
    _listToken = token;
    return _get(query, cancelToken: token);
  }

  Future<T?> findById(int id) => guard(() async {
    try {
      final response = await dio.get('/$resource/$id');
      return decode(_asMap(response.data));
    } on DioException catch (error) {
      if (mapDioError(error) is NotFoundException) return null;
      rethrow;
    }
  });

  Future<T> create(T item) => guard(() async {
    final response = await dio.post('/$resource', data: encode(item));
    final created = decode(_asMap(response.data));
    cache.add(created);
    return created;
  });

  Future<T> update(T item) => guard(() async {
    final response = await dio.put(
      '/$resource/${idOf(item)}',
      data: encode(item),
    );
    final saved = decode(_asMap(response.data));
    final index = cache.indexWhere((row) => idOf(row) == idOf(saved));
    if (index >= 0) {
      cache[index] = saved;
    } else {
      cache.add(saved);
    }
    return saved;
  });

  Future<void> softDelete(int id) => guard(() async {
    await dio.delete(
      '/$resource/$id',
      options: Options(responseType: ResponseType.plain),
    );
    await _reload();
  });

  Future<void> hardDelete(int id) => guard(() async {
    await dio.delete(
      '/$resource/$id',
      queryParameters: {'hard': true},
      options: Options(responseType: ResponseType.plain),
    );
    cache.removeWhere((item) => idOf(item) == id);
  });

  Future<void> restore(int id) => guard(() async {
    final response = await dio.post('/$resource/$id/restore');
    final saved = decode(_asMap(response.data));
    final index = cache.indexWhere((row) => idOf(row) == id);
    if (index >= 0) {
      cache[index] = saved;
    } else {
      cache.add(saved);
    }
  });

  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await dio.post(
      '/$resource/bulk-delete',
      data: {'ids': ids},
    );
    await _reload();
    return jsonInt(_asMap(response.data)['deleted']);
  });

  Future<PageResult<T>> _get(
    Map<String, dynamic> query, {
    CancelToken? cancelToken,
  }) => guard(() async {
    final response = await dio.get(
      '/$resource',
      queryParameters: query,
      cancelToken: cancelToken,
    );
    final data = _asMap(response.data);
    final items = [
      for (final item in (data['items'] as List? ?? const []))
        if (item is Map) decode(Map<String, dynamic>.from(item)),
    ];
    return PageResult(
      items: items,
      page: jsonInt(data['page'], 1),
      size: jsonInt(data['size'], 10),
      total: jsonInt(data['total']),
    );
  });

  Future<void> _reload() async {
    final loaded = <T>[];
    var page = 1;
    while (true) {
      final result = await _get({
        'page': page,
        'size': 100,
        'includeDeleted': true,
        'sort': 'id,asc',
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
