import 'package:dio/dio.dart';

import '../models/page_result.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import 'remote_collection.dart';
import 'workshop_repository.dart';

class ApiWorkshopRepository implements WorkshopRepository {
  ApiWorkshopRepository(Dio dio)
      : _remote = RemoteCollection<Workshop>(
          dio: dio,
          resource: 'workshops',
          decode: Workshop.fromJson,
          encode: _write,
          idOf: (item) => item.id,
        );

  final RemoteCollection<Workshop> _remote;

  Future<void> warm() => _remote.warm();

  @override
  List<Workshop> get all => _remote.all;

  @override
  Future<PageResult<Workshop>> find(WorkshopQuery query) {
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.city != null) 'city': query.city,
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Workshop?> findById(int id) => _remote.findById(id);

  @override
  Future<Workshop> create(Workshop workshop) => _remote.create(workshop);

  @override
  Future<Workshop> update(Workshop workshop) => _remote.update(workshop);

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _remote.hardDelete(id);

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);
}

Map<String, dynamic> _write(Workshop item) => {
      'name': item.name,
      'city': item.city,
      'phone': item.phone,
      'flavorIds': item.flavorIds,
    };
