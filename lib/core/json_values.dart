int jsonInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

String jsonString(Object? value, [String fallback = '']) {
  if (value is String) return value;
  if (value == null) return fallback;
  return value.toString();
}

bool jsonBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is String) {
    if (value == 'true') return true;
    if (value == 'false') return false;
  }
  return fallback;
}

List<int> jsonIntList(Object? value) {
  if (value is! List) return <int>[];
  return [for (final item in value) jsonInt(item)];
}

int jsonRelationId(Map<String, dynamic> json, String idKey, String objectKey, [int fallback = 0]) {
  final nested = json[objectKey];
  if (nested is Map && nested['id'] != null) return jsonInt(nested['id'], fallback);
  if (json[idKey] != null) return jsonInt(json[idKey], fallback);
  return fallback;
}

List<int> jsonRelationIds(Map<String, dynamic> json, String idsKey, String objectsKey) {
  final nested = json[objectsKey];
  if (nested is List && nested.any((item) => item is Map)) {
    return [
      for (final item in nested)
        if (item is Map) jsonInt(item['id']),
    ];
  }
  return jsonIntList(json[idsKey]);
}

DateTime? jsonDate(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return DateTime.tryParse(value);
}
