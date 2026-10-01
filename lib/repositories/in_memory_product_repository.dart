import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  InMemoryProductRepository({JsonStore? store}) : _store = store {
    if (store == null) {
      _products = [...seedProducts];
    } else {
      _products = store.load(
        key: StorageKeys.products,
        seed: seedProducts,
        fromJson: Product.fromJson,
        toJson: (item) => item.toJson(),
      );
    }
    _nextId = _maxId(_products) + 1;
  }

  final JsonStore? _store;
  late List<Product> _products;
  late int _nextId;

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.save(StorageKeys.products, _products, (item) => item.toJson());
  }

  @override
  bool skuExists(String sku, {int? exceptId}) {
    final needle = sku.trim().toLowerCase();
    return _products.any((p) => p.id != exceptId && p.sku.trim().toLowerCase() == needle);
  }

  @override
  int countByWorkshop(int workshopId) => _products.where((p) => p.workshopId == workshopId).length;

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (q.search.trim() == '!!!error') {
      throw StateError('Демонстрационная ошибка загрузки каталога');
    }

    var rows = _products.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) => p.name.toLowerCase().contains(needle) || p.sku.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.flavorTagId != null) {
      rows = rows.where((p) => p.flavorTagIds.contains(q.flavorTagId)).toList();
    }
    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((p) => p.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((p) => p.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'weight' => a.weightGrams.compareTo(b.weightGrams),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    return paginate(rows, q.page, q.size);
  }

  @override
  Future<Product?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<Product> create(Product product) async {
    if (skuExists(product.sku)) {
      throw StateError('Изделие с таким артикулом уже существует');
    }
    final created = Product(
      id: _nextId++,
      name: product.name.trim(),
      sku: product.sku.trim(),
      year: product.year,
      weightGrams: product.weightGrams,
      categoryId: product.categoryId,
      workshopId: product.workshopId,
      confectionerIds: product.confectionerIds,
      flavorTagIds: product.flavorTagIds,
      stockTotal: product.stockTotal,
      stockAvailable: product.stockAvailable,
    );
    _products.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    if (skuExists(product.sku, exceptId: product.id)) {
      throw StateError('Изделие с таким артикулом уже существует');
    }
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i == -1) throw StateError('Изделие ${product.id} не найдено');
    final saved = product.copyWith(deletedAt: _products[i].deletedAt);
    _products[i] = saved;
    await _persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Изделие $id не найдено');
    _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _products.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Изделие $id не найдено');
    _products[i] = _products[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _products.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}

int _maxId(List<Product> items) {
  var maxId = 0;
  for (final item in items) {
    if (item.id > maxId) maxId = item.id;
  }
  return maxId;
}
