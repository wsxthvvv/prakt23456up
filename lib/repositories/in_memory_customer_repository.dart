import '../data/seed_data.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'customer_repository.dart';

class InMemoryCustomerRepository implements CustomerRepository {
  InMemoryCustomerRepository({JsonStore? store}) : _store = store {
    _items = store == null
        ? [...seedCustomers]
        : store.load(
            key: StorageKeys.customers,
            seed: seedCustomers,
            fromJson: Customer.fromJson,
            toJson: (item) => item.toJson(),
          );
    _nextId = _maxId() + 1;
  }

  final JsonStore? _store;
  late List<Customer> _items;
  late int _nextId;

  @override
  List<Customer> get all => List.unmodifiable(_items);

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.save(StorageKeys.customers, _items, (item) => item.toJson());
  }

  int _maxId() {
    var maxId = 0;
    for (final item in _items) {
      if (item.id > maxId) maxId = item.id;
    }
    return maxId;
  }

  @override
  bool emailExists(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    return _items.any(
      (c) => c.id != exceptId && c.email.trim().toLowerCase() == needle,
    );
  }

  @override
  Future<PageResult<Customer>> find(CustomerQuery q) async {
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
                c.firstName.toLowerCase().contains(needle) ||
                c.email.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.cardActive != null) {
      rows = rows.where((c) => c.loyaltyCard.active == q.cardActive).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'discount' => a.loyaltyCard.discountPercent.compareTo(
          b.loyaltyCard.discountPercent,
        ),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    return paginate(rows, q.page, q.size);
  }

  @override
  Future<Customer?> findById(int id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<Customer> create(Customer customer) async {
    if (emailExists(customer.email)) {
      throw StateError('Покупатель с такой почтой уже существует');
    }
    final created = Customer(
      id: _nextId++,
      lastName: customer.lastName.trim(),
      firstName: customer.firstName.trim(),
      email: customer.email.trim(),
      phone: customer.phone.trim(),
      loyaltyCard: customer.loyaltyCard,
    );
    _items.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Customer> update(Customer customer) async {
    if (emailExists(customer.email, exceptId: customer.id)) {
      throw StateError('Покупатель с такой почтой уже существует');
    }
    final i = _items.indexWhere((c) => c.id == customer.id);
    if (i == -1) throw StateError('Покупатель ${customer.id} не найден');
    final saved = customer.copyWith(deletedAt: _items[i].deletedAt);
    _items[i] = saved;
    await _persist();
    return saved;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _items.indexWhere((c) => c.id == id);
    if (i == -1) throw StateError('Покупатель $id не найден');
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
    if (i == -1) throw StateError('Покупатель $id не найден');
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
