import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';
import 'remote_collection.dart';

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(Dio dio)
      : _remote = RemoteCollection<Product>(
          dio: dio,
          resource: 'products',
          decode: Product.fromJson,
          encode: _write,
          idOf: (item) => item.id,
        );

  final RemoteCollection<Product> _remote;

  Future<void> warm() => _remote.warm();

  @override
  Future<PageResult<Product>> find(ProductQuery query) {
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.flavorTagId != null) 'flavorTagId': query.flavorTagId,
      if (query.categoryId != null) 'categoryId': query.categoryId,
      if (query.yearFrom != null) 'yearFrom': query.yearFrom,
      if (query.yearTo != null) 'yearTo': query.yearTo,
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Product?> findById(int id) => _remote.findById(id);

  @override
  Future<Product> create(Product product) => _remote.create(product);

  @override
  Future<Product> update(Product product) => _remote.update(product);

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _remote.hardDelete(id);

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);

  @override
  bool skuExists(String sku, {int? exceptId}) {
    final needle = sku.trim().toLowerCase();
    return _remote.cache.any((item) => item.id != exceptId && item.sku.toLowerCase() == needle);
  }

  @override
  int countByWorkshop(int workshopId) {
    return _remote.cache.where((item) => item.workshopId == workshopId).length;
  }
}

Map<String, dynamic> _write(Product product) => {
      'name': product.name,
      'sku': product.sku,
      'year': product.year,
      'weightGrams': product.weightGrams,
      'categoryId': product.categoryId,
      'workshopId': product.workshopId,
      'confectionerIds': product.confectionerIds,
      'flavorTagIds': product.flavorTagIds,
      'stockTotal': product.stockTotal,
      'stockAvailable': product.stockAvailable,
    };
