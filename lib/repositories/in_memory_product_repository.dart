import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final List<Product> _products = [...seedProducts];
  int _nextId = seedProducts.length + 1;

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
            (p) =>
                p.name.toLowerCase().contains(needle) ||
                p.sku.toLowerCase().contains(needle),
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

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Product?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> create(Product product) async {
    final created = Product(
      id: _nextId++,
      name: product.name,
      sku: product.sku,
      year: product.year,
      weightGrams: product.weightGrams,
      categoryId: product.categoryId,
      confectionerIds: product.confectionerIds,
      flavorTagIds: product.flavorTagIds,
      stockTotal: product.stockTotal,
      stockAvailable: product.stockAvailable,
    );
    _products.add(created);
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i == -1) throw StateError('Изделие ${product.id} не найдено');
    _products[i] = product;
    return product;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Изделие $id не найдено');
    _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Изделие $id не найдено');
    _products[i] = _products[i].copyWith(clearDeletedAt: true);
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
    return count;
  }
}
