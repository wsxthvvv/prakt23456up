import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/models/product_query.dart';
import 'package:prakt2up/repositories/in_memory_product_repository.dart';

void main() {
  test('deleteMany performs logical delete', () async {
    final repo = InMemoryProductRepository();
    final before = await repo.find(const ProductQuery(size: 50));
    final id = before.items.first.id;

    final deleted = await repo.deleteMany([id]);
    expect(deleted, 1);

    final after = await repo.find(const ProductQuery(size: 50));
    expect(after.items.any((p) => p.id == id), isFalse);

    final withDeleted = await repo.find(const ProductQuery(size: 50, includeDeleted: true));
    expect(withDeleted.items.any((p) => p.id == id && p.isDeleted), isTrue);
  });
}
