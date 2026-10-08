import 'package:dio/dio.dart';

import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';
import 'customer_repository.dart';
import 'remote_collection.dart';

class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(Dio dio)
    : _remote = RemoteCollection<Customer>(
        dio: dio,
        resource: 'customers',
        decode: Customer.fromJson,
        encode: _write,
        idOf: (item) => item.id,
      );

  final RemoteCollection<Customer> _remote;

  Future<void> warm() => _remote.warm();

  @override
  List<Customer> get all => _remote.all;

  @override
  Future<PageResult<Customer>> find(CustomerQuery query) {
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.cardActive != null) 'cardActive': query.cardActive,
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Customer?> findById(int id) => _remote.findById(id);

  @override
  Future<Customer> create(Customer customer) => _remote.create(customer);

  @override
  Future<Customer> update(Customer customer) => _remote.update(customer);

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _remote.hardDelete(id);

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);

  @override
  bool emailExists(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    return _remote.cache.any(
      (item) => item.id != exceptId && item.email.toLowerCase() == needle,
    );
  }
}

Map<String, dynamic> _write(Customer item) => {
  'lastName': item.lastName,
  'firstName': item.firstName,
  'email': item.email,
  'phone': item.phone,
  'loyaltyCard': item.loyaltyCard.toJson(),
};
