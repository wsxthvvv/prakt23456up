import '../data/seed_data.dart';
import '../models/named_option.dart';
import '../models/product_category.dart';
import '../storage/json_store.dart';
import '../storage/storage_keys.dart';
import 'reference_repository.dart';

class InMemoryReferenceRepository implements ReferenceRepository {
  InMemoryReferenceRepository({JsonStore? store}) {
    if (store == null) {
      _categories = [...seedCategories];
      _countries = [...seedCountries];
      _specialties = [...seedSpecialties];
      return;
    }
    _categories = store.load(
      key: StorageKeys.categories,
      seed: seedCategories,
      fromJson: ProductCategory.fromJson,
      toJson: (item) => item.toJson(),
    );
    _countries = _names(
      store.load(
        key: StorageKeys.countries,
        seed: [for (final name in seedCountries) NamedOption(name)],
        fromJson: NamedOption.fromJson,
        toJson: (item) => item.toJson(),
      ),
    );
    _specialties = _names(
      store.load(
        key: StorageKeys.specialties,
        seed: [for (final name in seedSpecialties) NamedOption(name)],
        fromJson: NamedOption.fromJson,
        toJson: (item) => item.toJson(),
      ),
    );
  }

  late final List<ProductCategory> _categories;
  late final List<String> _countries;
  late final List<String> _specialties;

  @override
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  @override
  List<String> get countries => List.unmodifiable(_countries);

  @override
  List<String> get specialties => List.unmodifiable(_specialties);

  @override
  String categoryName(int id) {
    for (final category in _categories) {
      if (category.id == id) return category.name;
    }
    return '—';
  }

  List<String> _names(List<NamedOption> items) {
    return [
      for (final item in items)
        if (item.name.trim().isNotEmpty) item.name,
    ];
  }
}
