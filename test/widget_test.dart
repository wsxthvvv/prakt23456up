import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/data/seed_data.dart';
import 'package:prakt2up/models/product.dart';
import 'package:prakt2up/models/product_query.dart';
import 'package:prakt2up/repositories/in_memory_product_repository.dart';
import 'package:prakt2up/routing/router.dart';

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

  test('product fromJson tolerates missing and null fields', () {
    final product = Product.fromJson({
      'id': 7,
      'name': null,
      'workshopId': null,
    });
    expect(product.id, 7);
    expect(product.name, '');
    expect(product.workshopId, 1);
    expect(product.flavorTagIds, isEmpty);
    expect(product.deletedAt, isNull);
  });

  test('seed products stay inside workshop flavors and confectioners', () {
    for (final product in seedProducts) {
      final workshop = seedWorkshops.firstWhere((item) => item.id == product.workshopId);
      for (final flavorId in product.flavorTagIds) {
        expect(workshop.flavorIds, contains(flavorId), reason: 'изделие ${product.id}, вкус $flavorId');
      }
      for (final confectionerId in product.confectionerIds) {
        final confectioner = seedConfectioners.firstWhere((item) => item.id == confectionerId);
        expect(
          confectioner.workshopId,
          product.workshopId,
          reason: 'изделие ${product.id}, кондитер $confectionerId',
        );
      }
    }
    expect(seedProducts.map((item) => item.sku).toSet(), hasLength(seedProducts.length));
    expect(seedCustomers.map((item) => item.email).toSet(), hasLength(seedCustomers.length));
  });

  test('router includes practice 3 sections', () {
    expect(appRouter.routeInformationProvider, isNotNull);
  });

  test('duplicate sku is rejected', () async {
    final repo = InMemoryProductRepository();
    final existing = (await repo.find(const ProductQuery(size: 50))).items.first;
    await expectLater(
      repo.create(
        Product(
          id: 0,
          name: 'Дубликат',
          sku: existing.sku.toLowerCase(),
          year: 2024,
          weightGrams: 100,
          categoryId: 1,
          workshopId: 1,
          confectionerIds: const [1],
          flavorTagIds: const [2],
          stockTotal: 1,
          stockAvailable: 1,
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
