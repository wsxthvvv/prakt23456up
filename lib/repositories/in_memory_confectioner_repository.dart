import '../data/seed_data.dart';
import '../models/confectioner.dart';
import '../models/confectioner_query.dart';
import '../models/page_result.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'confectioner_repository.dart';

class InMemoryConfectionerRepository implements ConfectionerRepository {
  InMemoryConfectionerRepository({JsonStore? store}) : _store = store {
    if (store == null) {
      _items = [...seedConfectioners];
    } else {
      _items = store.load(
        key: StorageKeys.confectioners,
        seed: seedConfectioners,
        fromJson: Confectioner.fromJson,
        toJson: (item) => item.toJson(),
      );
    }
    _nextId = _maxId() + 1;
  }

  final JsonStore? _store;
  late List<Confectioner> _items;
  late int _nextId;

  @override
  List<Confectioner> get all => List.unmodifiable(_items);

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.save(
      StorageKeys.confectioners,
      _items,
      (item) => item.toJson(),
    );
  }

  int _maxId() {
    var maxId = 0;
    for (final item in _items) {
      if (item.id > maxId) maxId = item.id;
    }
    return maxId;
  }

  @override
  Future<PageResult<Confectioner>> find(ConfectionerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (q.search.trim() == '!!!error') {
      throw StateError('Демонстрационная ошибка загрузки списка');
    }

    var rows = _items.where((c) => q.includeDeleted || !c.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (c) =>
                c.lastName.toLowerCase().contains(needle) ||
                c.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((c) => c.country == q.country).toList();
    }
    if (q.specialty != null && q.specialty!.isNotEmpty) {
      rows = rows.where((c) => c.specialty == q.specialty).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'specialty' => a.specialty.toLowerCase().compareTo(
          b.specialty.toLowerCase(),
        ),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    return paginate(rows, q.page, q.size);
  }

  @override
  Future<Confectioner?> findById(int id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Confectioner> create(Confectioner confectioner) async {
    final created = Confectioner(
      id: _nextId++,
      lastName: confectioner.lastName.trim(),
      firstName: confectioner.firstName.trim(),
      country: confectioner.country.trim(),
      specialty: confectioner.specialty.trim(),
      workshopId: confectioner.workshopId,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Confectioner> update(Confectioner confectioner) async {
    final i = _items.indexWhere((c) => c.id == confectioner.id);
    if (i == -1) throw StateError('Кондитер ${confectioner.id} не найден');
    final saved = confectioner.copyWith(deletedAt: _items[i].deletedAt);
    _items[i] = saved;
    await _persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Кондитер $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((c) => c.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Кондитер $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _items.indexWhere((c) => c.id == id && !c.isDeleted);
      if (i != -1) {
        _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
