import '../core/json_values.dart';

class Product {
  final int id;
  final String name;
  final String sku;
  final int year;
  final int weightGrams;
  final int categoryId;
  final int workshopId;
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
    required this.workshopId,
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
    int? workshopId,
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
      workshopId: workshopId ?? this.workshopId,
      confectionerIds: confectionerIds ?? this.confectionerIds,
      flavorTagIds: flavorTagIds ?? this.flavorTagIds,
      stockTotal: stockTotal ?? this.stockTotal,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'year': year,
    'weightGrams': weightGrams,
    'categoryId': categoryId,
    'workshopId': workshopId,
    'confectionerIds': confectionerIds,
    'flavorTagIds': flavorTagIds,
    'stockTotal': stockTotal,
    'stockAvailable': stockAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    sku: jsonString(json['sku']),
    year: jsonInt(json['year']),
    weightGrams: jsonInt(json['weightGrams']),
    categoryId: jsonRelationId(json, 'categoryId', 'category', 1),
    workshopId: jsonRelationId(json, 'workshopId', 'workshop', 1),
    confectionerIds: jsonRelationIds(json, 'confectionerIds', 'confectioners'),
    flavorTagIds: jsonRelationIds(json, 'flavorTagIds', 'flavors'),
    stockTotal: jsonInt(json['stockTotal']),
    stockAvailable: jsonInt(json['stockAvailable']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}
