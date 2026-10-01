import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';

class AppStorage extends ChangeNotifier {
  AppStorage(this.prefs, String? notice) : _notice = notice;

  final SharedPreferences prefs;
  String? _notice;

  String? get notice => _notice;

  static Future<AppStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    final messages = <String>[];
    final stored = prefs.getInt(StorageKeys.versionKey);
    final legacy = prefs.getString(StorageKeys.legacyProducts);

    if (legacy != null) {
      try {
        final decoded = jsonDecode(legacy);
        if (decoded is! List) {
          throw const FormatException('legacy payload is not a list');
        }
        messages.add(
          'Найден ключ хранилища v1. Формат сменён на v${StorageKeys.version}: старые записи не подмешиваются, приложение продолжило работу на текущем каталоге.',
        );
      } catch (_) {
        messages.add(
          'Ключ v1 содержит данные старого или повреждённого формата. Они пропущены, приложение не остановлено. Используется каталог версии v${StorageKeys.version}.',
        );
      }
      await prefs.remove(StorageKeys.legacyProducts);
    }

    if (stored != null && stored != StorageKeys.version) {
      messages.add(
        'Версия формата в браузере: $stored, приложение ожидает v${StorageKeys.version}. Записи несовместимого ключа не читаются.',
      );
    }

    if (stored != StorageKeys.version) {
      await prefs.setInt(StorageKeys.versionKey, StorageKeys.version);
    }

    return AppStorage(prefs, messages.isEmpty ? null : messages.join(' '));
  }

  void report(String message) {
    if (message.trim().isEmpty) return;
    if (_notice == null || _notice!.isEmpty) {
      _notice = message;
    } else if (!_notice!.contains(message)) {
      _notice = '$_notice $message';
    }
    notifyListeners();
  }

  void dismiss() {
    _notice = null;
    notifyListeners();
  }
}
