import 'package:dio/dio.dart';

import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../models/page_result.dart';
import 'flavor_repository.dart';
import 'remote_collection.dart';

class ApiFlavorRepository implements FlavorRepository {
  ApiFlavorRepository(Dio dio)
      : _remote = RemoteCollection<Flavor>(
          dio: dio,
          resource: 'flavors',
          decode: Flavor.fromJson,
          encode: _write,
          idOf: (item) => item.id,
        );

  final RemoteCollection<Flavor> _remote;

  Future<void> warm() => _remote.warm();

  @override
  List<Flavor> get all => _remote.all;

  @override
  Future<PageResult<Flavor>> find(FlavorQuery query) {
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.intensity != null) 'intensity': query.intensity,
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Flavor?> findById(int id) => _remote.findById(id);

  @override
  Future<Flavor> create(Flavor flavor) => _remote.create(flavor);

  @override
  Future<Flavor> update(Flavor flavor) => _remote.update(flavor);

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _remote.hardDelete(id);

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);
}

Map<String, dynamic> _write(Flavor item) => {
      'name': item.name,
      'description': item.description,
      'intensity': item.intensity,
    };
