import '../data/seed_data.dart';
import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../models/page_result.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'flavor_repository.dart';

class InMemoryFlavorRepository implements FlavorRepository {
  InMemoryFlavorRepository({JsonStore? store}) : _store = store {
    _items = store == null
        ? [...seedFlavors]
        : store.load(
            key: StorageKeys.flavors,
            seed: seedFlavors,
            fromJson: Flavor.fromJson,
            toJson: (item) => item.toJson(),
          );
    _nextId = _maxId() + 1;
  }

  final JsonStore? _store;
  late List<Flavor> _items;
  late int _nextId;

  @override
  List<Flavor> get all => List.unmodifiable(_items);

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.save(StorageKeys.flavors, _items, (item) => item.toJson());
  }

  int _maxId() {
    var maxId = 0;
    for (final item in _items) {
      if (item.id > maxId) maxId = item.id;
    }
    return maxId;
  }

  @override
  Future<PageResult<Flavor>> find(FlavorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (q.search.trim() == '!!!error') {
      throw StateError('Демонстрационная ошибка загрузки списка');
    }

    var rows = _items.where((f) => q.includeDeleted || !f.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (f) =>
                f.name.toLowerCase().contains(needle) ||
                f.description.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.intensity != null) {
      rows = rows.where((f) => f.intensity == q.intensity).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'intensity' => a.intensity.compareTo(b.intensity),
        'description' => a.description.toLowerCase().compareTo(
          b.description.toLowerCase(),
        ),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, q.page, q.size);
  }

  @override
  Future<Flavor?> findById(int id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Flavor> create(Flavor flavor) async {
    final created = Flavor(
      id: _nextId++,
      name: flavor.name.trim(),
      description: flavor.description.trim(),
      intensity: flavor.intensity,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Flavor> update(Flavor flavor) async {
    final i = _items.indexWhere((f) => f.id == flavor.id);
    if (i == -1) throw StateError('Вкус ${flavor.id} не найден');
    final saved = flavor.copyWith(deletedAt: _items[i].deletedAt);
    _items[i] = saved;
    await _persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((f) => f.id == id);
    if (i == -1) throw StateError('Вкус $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((f) => f.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((f) => f.id == id);
    if (i == -1) throw StateError('Вкус $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((f) => f.id == id && !f.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
