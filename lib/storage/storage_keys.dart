class StorageKeys {
  static const version = 2;
  static const versionKey = 'nyamka_schema_version';
  static const legacyProducts = 'nyamka_products_v1';

  static const products = 'nyamka_products_v$version';
  static const confectioners = 'nyamka_confectioners_v$version';
  static const flavors = 'nyamka_flavors_v$version';
  static const workshops = 'nyamka_workshops_v$version';
  static const customers = 'nyamka_customers_v$version';
  static const categories = 'nyamka_categories_v$version';
  static const countries = 'nyamka_countries_v$version';
  static const specialties = 'nyamka_specialties_v$version';
}
