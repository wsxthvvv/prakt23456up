import 'dart:convert';

import 'app_storage.dart';

class JsonStore {
  JsonStore(this.storage);

  final AppStorage storage;
  final List<Future<void>> _pending = [];

  Future<void> flush() => Future.wait(List<Future<void>>.of(_pending));

  List<T> load<T>({
    required String key,
    required List<T> seed,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T item) toJson,
  }) {
    final raw = storage.prefs.getString(key);
    if (raw == null) {
      final initial = List<T>.of(seed);
      _pending.add(save(key, initial, toJson));
      return initial;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('expected list');
      }
      return [
        for (final item in decoded)
          if (item is Map)
            fromJson(Map<String, dynamic>.from(item))
          else
            throw const FormatException('expected object'),
      ];
    } catch (_) {
      storage.report(
        'Данные «$key» повреждены или записаны в старом формате. Загружен начальный набор, сбоя запуска нет.',
      );
      final initial = List<T>.of(seed);
      _pending.add(save(key, initial, toJson));
      return initial;
    }
  }

  Future<void> save<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T item) toJson,
  ) {
    return storage.prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
