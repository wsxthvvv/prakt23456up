class ProductCategory {
  final int id;
  final String name;

  const ProductCategory({required this.id, required this.name});
}

class FlavorTag {
  final int id;
  final String name;

  const FlavorTag({required this.id, required this.name});
}

const productCategories = [
  ProductCategory(id: 1, name: 'Торты'),
  ProductCategory(id: 2, name: 'Пирожные'),
  ProductCategory(id: 3, name: 'Печенье'),
  ProductCategory(id: 4, name: 'Хлеб сладкий'),
  ProductCategory(id: 5, name: 'Десерты в стаканчиках'),
];

const flavorTags = [
  FlavorTag(id: 1, name: 'Шоколад'),
  FlavorTag(id: 2, name: 'Ваниль'),
  FlavorTag(id: 3, name: 'Ягоды'),
  FlavorTag(id: 4, name: 'Орехи'),
  FlavorTag(id: 5, name: 'Карамель'),
];

String categoryName(int id) =>
    productCategories.firstWhere((c) => c.id == id, orElse: () => const ProductCategory(id: 0, name: '—')).name;

String flavorNames(List<int> ids) {
  if (ids.isEmpty) return '—';
  return ids
      .map((id) => flavorTags.firstWhere((t) => t.id == id, orElse: () => FlavorTag(id: id, name: '?')).name)
      .join(', ');
}

const confectionerCountries = ['Россия', 'Франция', 'Италия', 'Бельгия'];
const confectionerSpecialties = ['Торты', 'Пирожные', 'Десерты', 'Выпечка', 'Шоколад'];
