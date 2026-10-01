import '../models/product_category.dart';

abstract interface class ReferenceRepository {
  List<ProductCategory> get categories;
  List<String> get countries;
  List<String> get specialties;
  String categoryName(int id);
}
