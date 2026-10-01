import '../models/confectioner.dart';
import '../models/confectioner_query.dart';
import '../models/page_result.dart';

abstract interface class ConfectionerRepository {
  List<Confectioner> get all;
  Future<PageResult<Confectioner>> find(ConfectionerQuery query);
  Future<Confectioner?> findById(int id);
  Future<Confectioner> create(Confectioner confectioner);
  Future<Confectioner> update(Confectioner confectioner);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
