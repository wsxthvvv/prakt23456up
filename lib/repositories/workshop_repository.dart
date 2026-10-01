import '../models/page_result.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';

abstract interface class WorkshopRepository {
  List<Workshop> get all;
  Future<PageResult<Workshop>> find(WorkshopQuery query);
  Future<Workshop?> findById(int id);
  Future<Workshop> create(Workshop workshop);
  Future<Workshop> update(Workshop workshop);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
