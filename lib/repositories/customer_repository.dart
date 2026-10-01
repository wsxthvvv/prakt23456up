import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/page_result.dart';

abstract interface class CustomerRepository {
  List<Customer> get all;
  Future<PageResult<Customer>> find(CustomerQuery query);
  Future<Customer?> findById(int id);
  Future<Customer> create(Customer customer);
  Future<Customer> update(Customer customer);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  bool emailExists(String email, {int? exceptId});
}
