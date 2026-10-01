import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../models/page_result.dart';

abstract interface class FlavorRepository {
  List<Flavor> get all;
  Future<PageResult<Flavor>> find(FlavorQuery query);
  Future<Flavor?> findById(int id);
  Future<Flavor> create(Flavor flavor);
  Future<Flavor> update(Flavor flavor);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
