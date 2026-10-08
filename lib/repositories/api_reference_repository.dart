import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../core/pb_links.dart';
import '../data/seed_data.dart';
import '../models/product_category.dart';
import 'reference_repository.dart';

class ApiReferenceRepository implements ReferenceRepository {
  ApiReferenceRepository(this._dio, {PbLinks? links})
    : _links = links ?? PbLinks.shared;

  final Dio _dio;
  final PbLinks _links;
  bool _loaded = false;
  List<ProductCategory> _categories = const [];

  Future<void> warm() async {
    if (_loaded) return;
    final response = await guard(
      () => _dio.get(
        '/collections/categories/records',
        queryParameters: {
          'page': 1,
          'perPage': 100,
          'sort': 'code',
          'filter': 'deleted = false',
        },
      ),
    );
    final data = response.data;
    final items = data is Map && data['items'] is List
        ? data['items'] as List
        : const [];
    _categories = [
      for (final item in items)
        if (item is Map)
          ProductCategory(
            id: jsonInt(item['code']),
            name: jsonString(item['name']),
          ),
    ];
    for (final item in items) {
      if (item is Map) {
        _links.remember(
          'categories',
          jsonInt(item['code']),
          jsonString(item['id']),
        );
      }
    }
    _loaded = true;
  }

  @override
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  @override
  List<String> get countries => seedCountries;

  @override
  List<String> get specialties => seedSpecialties;

  @override
  String categoryName(int id) {
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return 'Категория $id';
  }
}
