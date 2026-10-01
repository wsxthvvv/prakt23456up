import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../models/product_category.dart';
import 'reference_repository.dart';

class ApiReferenceRepository implements ReferenceRepository {
  ApiReferenceRepository(this._dio);

  final Dio _dio;
  bool _loaded = false;
  List<ProductCategory> _categories = const [];
  List<String> _countries = const [];
  List<String> _specialties = const [];

  Future<void> warm() async {
    if (_loaded) return;
    final categories = await _items('/categories');
    final countries = await _items('/countries');
    final specialties = await _items('/specialties');
    _categories = [
      for (final item in categories)
        if (item is Map) ProductCategory.fromJson(Map<String, dynamic>.from(item)),
    ];
    _countries = [for (final item in countries) jsonString(item)];
    _specialties = [for (final item in specialties) jsonString(item)];
    _loaded = true;
  }

  Future<List<dynamic>> _items(String path) => guard(() async {
        final response = await _dio.get(path, queryParameters: {'page': 1, 'size': 100});
        final data = response.data;
        if (data is Map && data['items'] is List) return data['items'] as List;
        throw const ServerException('Сервер вернул неожиданный ответ.');
      });

  @override
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  @override
  List<String> get countries => List.unmodifiable(_countries);

  @override
  List<String> get specialties => List.unmodifiable(_specialties);

  @override
  String categoryName(int id) {
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return 'Категория $id';
  }
}
