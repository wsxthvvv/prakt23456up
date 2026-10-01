class Product {
  final int id;
  final String name;
  final String sku;
  final int year;
  final int weightGrams;
  final int categoryId;
  final List<int> confectionerIds;
  final List<int> flavorTagIds;
  final int stockTotal;
  final int stockAvailable;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.year,
    required this.weightGrams,
    required this.categoryId,
    required this.confectionerIds,
    required this.flavorTagIds,
    required this.stockTotal,
    required this.stockAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? sku,
    int? year,
    int? weightGrams,
    int? categoryId,
    List<int>? confectionerIds,
    List<int>? flavorTagIds,
    int? stockTotal,
    int? stockAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      year: year ?? this.year,
      weightGrams: weightGrams ?? this.weightGrams,
      categoryId: categoryId ?? this.categoryId,
      confectionerIds: confectionerIds ?? this.confectionerIds,
      flavorTagIds: flavorTagIds ?? this.flavorTagIds,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
