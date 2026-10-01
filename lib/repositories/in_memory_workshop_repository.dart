import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'workshop_repository.dart';

class InMemoryWorkshopRepository implements WorkshopRepository {
  InMemoryWorkshopRepository({JsonStore? store}) : _store = store {
    _items = store == null
        ? [...seedWorkshops]
        : store.load(
            key: StorageKeys.workshops,
            seed: seedWorkshops,
            fromJson: Workshop.fromJson,
            toJson: (item) => item.toJson(),
          );
    _nextId = _maxId() + 1;
  }

  final JsonStore? _store;
  late List<Workshop> _items;
  late int _nextId;

  @override
  List<Workshop> get all => List.unmodifiable(_items);

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.save(StorageKeys.workshops, _items, (item) => item.toJson());
  }

  int _maxId() {
    var maxId = 0;
    for (final item in _items) {
      if (item.id > maxId) maxId = item.id;
    }
    return maxId;
  }

  @override
  Future<PageResult<Workshop>> find(WorkshopQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (q.search.trim() == '!!!error') {
      throw StateError('Демонстрационная ошибка загрузки списка');
    }

    var rows = _items.where((w) => q.includeDeleted || !w.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (w) =>
                w.name.toLowerCase().contains(needle) ||
                w.city.toLowerCase().contains(needle) ||
                w.phone.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.city != null && q.city!.isNotEmpty) {
      rows = rows.where((w) => w.city == q.city).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'city' => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        'phone' => a.phone.compareTo(b.phone),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, q.page, q.size);
  }

  @override
  Future<Workshop?> findById(int id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Workshop> create(Workshop workshop) async {
    final created = Workshop(
      id: _nextId++,
      name: workshop.name.trim(),
      city: workshop.city.trim(),
      phone: workshop.phone.trim(),
      flavorIds: workshop.flavorIds,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Workshop> update(Workshop workshop) async {
    final i = _items.indexWhere((w) => w.id == workshop.id);
    if (i == -1) throw StateError('Цех ${workshop.id} не найден');
    final saved = workshop.copyWith(deletedAt: _items[i].deletedAt);
    _items[i] = saved;
    await _persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Цех $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((w) => w.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((w) => w.id == id);
    if (i == -1) throw StateError('Цех $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((w) => w.id == id && !w.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
