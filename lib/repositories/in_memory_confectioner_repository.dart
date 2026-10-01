import '../data/seed_data.dart';
import '../models/confectioner.dart';
import '../models/confectioner_query.dart';
import '../models/page_result.dart';
import 'confectioner_repository.dart';

class InMemoryConfectionerRepository implements ConfectionerRepository {
  final List<Confectioner> _items = [...seedConfectioners];

  @override
  Future<PageResult<Confectioner>> find(ConfectionerQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

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
        'firstName' => a.firstName.toLowerCase().compareTo(b.firstName.toLowerCase()),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'specialty' => a.specialty.toLowerCase().compareTo(b.specialty.toLowerCase()),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Confectioner>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Confectioner?> findById(int id) async {
    try {
      return _items.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Кондитер $id не найден');
    _items[i] = _items[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _items.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Кондитер $id не найден');
    _items[i] = _items[i].copyWith(clearDeletedAt: true);
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
    return count;
  }
}
