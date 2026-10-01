import '../core/json_values.dart';

class ProductCategory {
  final int id;
  final String name;

  const ProductCategory({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ProductCategory.fromJson(Map<String, dynamic> json) => ProductCategory(
        id: jsonInt(json['id']),
        name: jsonString(json['name']),
      );
}
