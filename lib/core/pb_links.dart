/// Соответствие номера записи в интерфейсе и идентификатора PocketBase.
class PbLinks {
  static final shared = PbLinks();

  final Map<String, Map<int, String>> _ids = {};

  void remember(String collection, int code, String pbId) {
    if (code <= 0 || pbId.isEmpty) return;
    (_ids[collection] ??= {})[code] = pbId;
  }

  String? pbId(String collection, int code) => _ids[collection]?[code];

  int nextCode(String collection) {
    final codes = _ids[collection]?.keys;
    if (codes == null || codes.isEmpty) return 1;
    var maxCode = 0;
    for (final code in codes) {
      if (code > maxCode) maxCode = code;
    }
    return maxCode + 1;
  }
}

class PbRelation {
  const PbRelation(this.collection, this.field, {this.many = false});

  final String collection;
  final String field;
  final bool many;
}

/// Как старые параметры списка переводятся в фильтр PocketBase.
class PbHints {
  const PbHints({
    this.searchFields = const [],
    this.equals = const {},
    this.relations = const {},
    this.minimum = const {},
    this.maximum = const {},
    this.expand = const [],
  });

  final List<String> searchFields;
  final Map<String, String> equals;
  final Map<String, PbRelation> relations;
  final Map<String, String> minimum;
  final Map<String, String> maximum;
  final List<String> expand;
}

String pbQuote(Object value) {
  final text = '$value'.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$text"';
}
