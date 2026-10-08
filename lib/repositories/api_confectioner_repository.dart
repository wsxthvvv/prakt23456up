import 'package:dio/dio.dart';

import '../models/confectioner.dart';
import '../models/confectioner_query.dart';
import '../models/page_result.dart';
import 'confectioner_repository.dart';
import 'remote_collection.dart';

class ApiConfectionerRepository implements ConfectionerRepository {
  ApiConfectionerRepository(Dio dio)
    : _remote = RemoteCollection<Confectioner>(
        dio: dio,
        resource: 'confectioners',
        decode: Confectioner.fromJson,
        encode: _write,
        idOf: (item) => item.id,
      );

  final RemoteCollection<Confectioner> _remote;

  Future<void> warm() => _remote.warm();

  @override
  List<Confectioner> get all => _remote.all;

  @override
  Future<PageResult<Confectioner>> find(ConfectionerQuery query) {
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (query.country != null) 'country': query.country,
      if (query.specialty != null) 'specialty': query.specialty,
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Confectioner?> findById(int id) => _remote.findById(id);

  @override
  Future<Confectioner> create(Confectioner confectioner) =>
      _remote.create(confectioner);

  @override
  Future<Confectioner> update(Confectioner confectioner) =>
      _remote.update(confectioner);

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) => _remote.hardDelete(id);

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);
}

Map<String, dynamic> _write(Confectioner item) => {
  'lastName': item.lastName,
  'firstName': item.firstName,
  'country': item.country,
  'specialty': item.specialty,
  'workshopId': item.workshopId,
};
