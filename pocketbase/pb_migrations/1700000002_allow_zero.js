/// Число 0 в обязательном поле PocketBase считает пустым.
/// Скидка и сумма заказа могут быть нулевыми.

migrate(
  (app) => {
    allowZero(app, 'orders', 'discountPercent');
    allowZero(app, 'orders', 'totalRub');
    allowZero(app, 'products', 'stockTotal');
    allowZero(app, 'products', 'stockAvailable');
    allowZero(app, 'loyalty_cards', 'discountPercent');
  },
  (app) => {
    requireAgain(app, 'orders', 'discountPercent');
    requireAgain(app, 'orders', 'totalRub');
    requireAgain(app, 'products', 'stockTotal');
    requireAgain(app, 'products', 'stockAvailable');
    requireAgain(app, 'loyalty_cards', 'discountPercent');
  },
);

function allowZero(app, collectionName, fieldName) {
  const collection = app.findCollectionByNameOrId(collectionName);
  const field = collection.fields.getByName(fieldName);
  field.required = false;
  app.save(collection);
}

function requireAgain(app, collectionName, fieldName) {
  const collection = app.findCollectionByNameOrId(collectionName);
  const field = collection.fields.getByName(fieldName);
  field.required = true;
  app.save(collection);
}
