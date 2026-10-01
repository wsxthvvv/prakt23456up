import 'package:flutter/foundation.dart';

import '../models/page_result.dart';
import 'load_status.dart';

class CatalogNotifier<T, Q> extends ChangeNotifier {
  CatalogNotifier({
    required this.find,
    required this.softDelete,
    required this.hardDelete,
    required this.restore,
    required this.deleteMany,
    required Q initialQuery,
    this.errorPrefix = 'Не удалось загрузить список',
  }) : _query = initialQuery;

  final Future<PageResult<T>> Function(Q query) find;
  final Future<void> Function(int id) softDelete;
  final Future<void> Function(int id) hardDelete;
  final Future<void> Function(int id) restore;
  final Future<int> Function(List<int> ids) deleteMany;
  final String errorPrefix;

  Q _query;
  PageResult<T> _result = PageResult<T>.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};
  int _ticket = 0;

  Q get query => _query;
  PageResult<T> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    final ticket = ++_ticket;
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final result = await find(_query);
      if (ticket != _ticket) return;
      _result = result;
      _status = LoadStatus.success;
    } catch (e) {
      if (ticket != _ticket || '$e'.contains('отменён')) return;
      _error = '$errorPrefix: $e';
      _status = LoadStatus.error;
    }
    if (ticket == _ticket) notifyListeners();
  }

  Future<void> applyQuery(Q next) async {
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    await deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDeleteOne(int id) async {
    await softDelete(id);
    await load();
  }

  Future<void> hardDeleteOne(int id) async {
    await hardDelete(id);
    await load();
  }

  Future<void> restoreOne(int id) async {
    await restore(id);
    await load();
  }
}
