/// Схема кондитерской «нямка» для итогового проекта.
/// Связи: один к одному (покупатель — карта), один ко многим (цех — кондитеры,
/// покупатель — заказы), многие ко многим (изделие — вкусы и кондитеры).

migrate(
  (app) => {
    const authed = '@request.auth.id != ""';
    const staff =
      '@request.auth.role = "seller" || @request.auth.role = "admin"';
    const admin = '@request.auth.role = "admin"';

    const users = app.findCollectionByNameOrId('users');
    users.fields.add(
      new SelectField({
        name: 'role',
        required: true,
        maxSelect: 1,
        values: ['buyer', 'seller', 'admin'],
      }),
    );
    users.fields.add(
      new TextField({
        name: 'fullName',
        required: true,
        min: 2,
        max: 80,
      }),
    );
    users.fields.add(
      new TextField({
        name: 'username',
        required: false,
        min: 0,
        max: 40,
      }),
    );
    users.fields.add(
      new NumberField({
        name: 'code',
        required: true,
        onlyInt: true,
        min: 1,
      }),
    );
    users.createRule = '@request.body.role = "buyer"';
    users.listRule = admin;
    users.viewRule = authed;
    users.updateRule = admin;
    users.deleteRule = admin;
    app.save(users);

    const flavors = new Collection({
      type: 'base',
      name: 'flavors',
      listRule: authed,
      viewRule: authed,
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        text('name', 2, 80),
        text('description', 0, 300),
        numRange('intensity', 1, 10),
        flag('deleted'),
      ],
      indexes: ['CREATE UNIQUE INDEX idx_flavors_code ON flavors (code)'],
    });
    app.save(flavors);

    const categories = new Collection({
      type: 'base',
      name: 'categories',
      listRule: authed,
      viewRule: authed,
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [num('code'), text('name', 2, 80), flag('deleted')],
      indexes: [
        'CREATE UNIQUE INDEX idx_categories_code ON categories (code)',
        'CREATE UNIQUE INDEX idx_categories_name ON categories (name)',
      ],
    });
    app.save(categories);

    const workshops = new Collection({
      type: 'base',
      name: 'workshops',
      listRule: authed,
      viewRule: authed,
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        text('name', 2, 80),
        text('city', 2, 60),
        text('phone', 6, 20),
        numRange('dailyCapacityKg', 1, 10000),
        {
          name: 'flavors',
          type: 'relation',
          required: true,
          collectionId: flavors.id,
          minSelect: 1,
          maxSelect: 20,
        },
        flag('deleted'),
      ],
      indexes: ['CREATE UNIQUE INDEX idx_workshops_code ON workshops (code)'],
    });
    app.save(workshops);

    const confectioners = new Collection({
      type: 'base',
      name: 'confectioners',
      listRule: authed,
      viewRule: authed,
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        text('lastName', 2, 60),
        text('firstName', 2, 60),
        text('country', 2, 60),
        text('specialty', 2, 60),
        {
          name: 'workshop',
          type: 'relation',
          required: true,
          collectionId: workshops.id,
          maxSelect: 1,
          cascadeDelete: false,
        },
        flag('deleted'),
      ],
      indexes: [
        'CREATE UNIQUE INDEX idx_confectioners_code ON confectioners (code)',
      ],
    });
    app.save(confectioners);

    const products = new Collection({
      type: 'base',
      name: 'products',
      listRule: authed,
      viewRule: authed,
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        text('name', 2, 120),
        text('sku', 3, 32),
        numRange('year', 1990, 2100),
        numRange('weightGrams', 1, 20000),
        numRange('priceRub', 1, 100000),
        {
          name: 'category',
          type: 'relation',
          required: true,
          collectionId: categories.id,
          maxSelect: 1,
        },
        {
          name: 'workshop',
          type: 'relation',
          required: true,
          collectionId: workshops.id,
          maxSelect: 1,
        },
        {
          name: 'confectioners',
          type: 'relation',
          required: true,
          collectionId: confectioners.id,
          minSelect: 1,
          maxSelect: 12,
        },
        {
          name: 'flavors',
          type: 'relation',
          required: true,
          collectionId: flavors.id,
          minSelect: 1,
          maxSelect: 12,
        },
        numRange('stockTotal', 0, 100000),
        numRange('stockAvailable', 0, 100000),
        flag('deleted'),
      ],
      indexes: [
        'CREATE UNIQUE INDEX idx_products_code ON products (code)',
        'CREATE UNIQUE INDEX idx_products_sku ON products (sku)',
      ],
    });
    app.save(products);

    const customers = new Collection({
      type: 'base',
      name: 'customers',
      listRule: staff + ' || user = @request.auth.id',
      viewRule: staff + ' || user = @request.auth.id',
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        text('lastName', 2, 60),
        text('firstName', 2, 60),
        {
          name: 'email',
          type: 'email',
          required: true,
        },
        text('phone', 6, 20),
        {
          name: 'user',
          type: 'relation',
          required: false,
          collectionId: users.id,
          maxSelect: 1,
        },
        flag('deleted'),
      ],
      indexes: [
        'CREATE UNIQUE INDEX idx_customers_code ON customers (code)',
        'CREATE UNIQUE INDEX idx_customers_email ON customers (email)',
      ],
    });
    app.save(customers);

    const cards = new Collection({
      type: 'base',
      name: 'loyalty_cards',
      listRule: staff + ' || customer.user = @request.auth.id',
      viewRule: staff + ' || customer.user = @request.auth.id',
      createRule: staff,
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        {
          name: 'customer',
          type: 'relation',
          required: true,
          collectionId: customers.id,
          maxSelect: 1,
          cascadeDelete: true,
        },
        text('number', 4, 20),
        {
          name: 'issuedOn',
          type: 'date',
          required: true,
        },
        numRange('discountPercent', 0, 90),
        flag('active'),
        flag('deleted'),
      ],
      indexes: [
        'CREATE UNIQUE INDEX idx_cards_code ON loyalty_cards (code)',
        'CREATE UNIQUE INDEX idx_cards_customer ON loyalty_cards (customer)',
        'CREATE UNIQUE INDEX idx_cards_number ON loyalty_cards (number)',
      ],
    });
    app.save(cards);

    const orders = new Collection({
      type: 'base',
      name: 'orders',
      listRule:
        staff + ' || customer.user = @request.auth.id',
      viewRule: staff + ' || customer.user = @request.auth.id',
      createRule:
        staff +
        ' || ( @request.auth.role = "buyer" && customer.user = @request.auth.id )',
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        {
          name: 'customer',
          type: 'relation',
          required: true,
          collectionId: customers.id,
          maxSelect: 1,
        },
        {
          name: 'dueOn',
          type: 'date',
          required: true,
        },
        {
          name: 'status',
          type: 'select',
          required: true,
          maxSelect: 1,
          values: ['open', 'closed'],
        },
        numRange('discountPercent', 0, 90),
        numRange('totalRub', 0, 10000000),
        text('note', 0, 300),
        flag('deleted'),
      ],
      indexes: ['CREATE UNIQUE INDEX idx_orders_code ON orders (code)'],
    });
    app.save(orders);

    const lines = new Collection({
      type: 'base',
      name: 'order_lines',
      listRule: staff + ' || order.customer.user = @request.auth.id',
      viewRule: staff + ' || order.customer.user = @request.auth.id',
      createRule: staff + ' || order.customer.user = @request.auth.id',
      updateRule: staff,
      deleteRule: admin,
      fields: [
        num('code'),
        {
          name: 'order',
          type: 'relation',
          required: true,
          collectionId: orders.id,
          maxSelect: 1,
          cascadeDelete: true,
        },
        {
          name: 'product',
          type: 'relation',
          required: true,
          collectionId: products.id,
          maxSelect: 1,
        },
        numRange('qty', 1, 500),
        numRange('unitPriceRub', 1, 100000),
        flag('deleted'),
      ],
      indexes: ['CREATE UNIQUE INDEX idx_lines_code ON order_lines (code)'],
    });
    app.save(lines);

    const chocolate = row(app, flavors, {
      code: 1,
      name: 'Шоколад',
      description: 'Какао и тёмный шоколад',
      intensity: 5,
    });
    const vanilla = row(app, flavors, {
      code: 2,
      name: 'Ваниль',
      description: 'Классическая ваниль',
      intensity: 2,
    });
    const berry = row(app, flavors, {
      code: 3,
      name: 'Ягоды',
      description: 'Ягодные начинки',
      intensity: 4,
    });
    const nuts = row(app, flavors, {
      code: 4,
      name: 'Орехи',
      description: 'Миндаль и фундук',
      intensity: 3,
    });

    const cakes = row(app, categories, { code: 1, name: 'Торты' });
    const pastries = row(app, categories, { code: 2, name: 'Пирожные' });
    const cookies = row(app, categories, { code: 3, name: 'Печенье' });

    const hall = row(app, workshops, {
      code: 1,
      name: 'Цех на Патриарших',
      city: 'Москва',
      phone: '+74951112233',
      dailyCapacityKg: 8,
      flavors: [chocolate.id, vanilla.id, berry.id],
    });
    const yard = row(app, workshops, {
      code: 2,
      name: 'Цех на Литейном',
      city: 'Санкт-Петербург',
      phone: '+78125554433',
      dailyCapacityKg: 5,
      flavors: [nuts.id, vanilla.id],
    });

    const anna = row(app, confectioners, {
      code: 1,
      lastName: 'Лебедева',
      firstName: 'Мария',
      country: 'Россия',
      specialty: 'Торты',
      workshop: hall.id,
    });
    const pierre = row(app, confectioners, {
      code: 2,
      lastName: 'Моро',
      firstName: 'Пьер',
      country: 'Франция',
      specialty: 'Десерты',
      workshop: hall.id,
    });
    const giulia = row(app, confectioners, {
      code: 3,
      lastName: 'Росси',
      firstName: 'Джулия',
      country: 'Италия',
      specialty: 'Печенье',
      workshop: yard.id,
    });

    const napoleon = row(app, products, {
      code: 1,
      name: 'Наполеон',
      sku: 'NYM-NAP-01',
      year: 2024,
      weightGrams: 1200,
      priceRub: 1890,
      category: cakes.id,
      workshop: hall.id,
      confectioners: [anna.id],
      flavors: [vanilla.id],
      stockTotal: 12,
      stockAvailable: 9,
    });
    row(app, products, {
      code: 2,
      name: 'Прага',
      sku: 'NYM-PRG-02',
      year: 2023,
      weightGrams: 900,
      priceRub: 1650,
      category: cakes.id,
      workshop: hall.id,
      confectioners: [anna.id, pierre.id],
      flavors: [chocolate.id],
      stockTotal: 8,
      stockAvailable: 4,
    });
    const eclair = row(app, products, {
      code: 3,
      name: 'Эклер ягодный',
      sku: 'NYM-ECL-03',
      year: 2025,
      weightGrams: 90,
      priceRub: 220,
      category: pastries.id,
      workshop: hall.id,
      confectioners: [pierre.id],
      flavors: [berry.id, vanilla.id],
      stockTotal: 40,
      stockAvailable: 30,
    });
    row(app, products, {
      code: 4,
      name: 'Кантуччи',
      sku: 'NYM-KAN-04',
      year: 2022,
      weightGrams: 250,
      priceRub: 480,
      category: cookies.id,
      workshop: yard.id,
      confectioners: [giulia.id],
      flavors: [nuts.id],
      stockTotal: 20,
      stockAvailable: 15,
    });

    const sokolova = row(app, customers, {
      code: 1,
      lastName: 'Соколова',
      firstName: 'Анна',
      email: 'anna.sokolova@nyamka.test',
      phone: '+79031112233',
    });
    const ivanov = row(app, customers, {
      code: 2,
      lastName: 'Иванов',
      firstName: 'Пётр',
      email: 'petr.ivanov@nyamka.test',
      phone: '+79035556677',
    });

    row(app, cards, {
      code: 1,
      customer: sokolova.id,
      number: 'NY-1001',
      issuedOn: '2024-03-01 00:00:00.000Z',
      discountPercent: 10,
      active: true,
    });
    row(app, cards, {
      code: 2,
      customer: ivanov.id,
      number: 'NY-1002',
      issuedOn: '2025-01-15 00:00:00.000Z',
      discountPercent: 5,
      active: false,
    });

    const order = row(app, orders, {
      code: 1,
      customer: sokolova.id,
      dueOn: '2026-10-20 00:00:00.000Z',
      status: 'open',
      discountPercent: 10,
      totalRub: 1899,
      note: 'К чаю в субботу',
    });
    row(app, lines, {
      code: 1,
      order: order.id,
      product: napoleon.id,
      qty: 1,
      unitPriceRub: 1890,
    });
    row(app, lines, {
      code: 2,
      order: order.id,
      product: eclair.id,
      qty: 1,
      unitPriceRub: 220,
    });

    const adminUser = account(app, users, {
      code: 1,
      email: 'admin@nyamka.test',
      password: 'Admin123!',
      fullName: 'Администратор',
      username: 'admin',
      role: 'admin',
    });
    account(app, users, {
      code: 2,
      email: 'seller@nyamka.test',
      password: 'Seller123!',
      fullName: 'Продавец зала',
      username: 'seller',
      role: 'seller',
    });
    const buyer = account(app, users, {
      code: 3,
      email: 'buyer@nyamka.test',
      password: 'Buyer123!',
      fullName: 'Соколова Анна',
      username: 'buyer',
      role: 'buyer',
    });
    sokolova.set('user', buyer.id);
    app.save(sokolova);
    void adminUser;

    try {
      const supers = app.findCollectionByNameOrId('_superusers');
      const existing = app.findAuthRecordsByEmail(
        supers.id,
        'nyamka@local.test',
      );
      void existing;
    } catch (error) {
      try {
        const supers = app.findCollectionByNameOrId('_superusers');
        const superuser = new Record(supers);
        superuser.set('email', 'nyamka@local.test');
        superuser.set('password', 'Nyamka123!');
        app.save(superuser);
      } catch (ignored) {
        void ignored;
      }
    }
  },
  (app) => {
    const names = [
      'order_lines',
      'orders',
      'loyalty_cards',
      'customers',
      'products',
      'confectioners',
      'workshops',
      'categories',
      'flavors',
    ];
    for (const name of names) {
      try {
        app.delete(app.findCollectionByNameOrId(name));
      } catch (error) {
        void error;
      }
    }
  },
);

function text(name, min, max) {
  return {
    name: name,
    type: 'text',
    required: min > 0,
    min: min,
    max: max,
  };
}

function num(name) {
  return {
    name: name,
    type: 'number',
    required: true,
    onlyInt: true,
    min: 1,
  };
}

function numRange(name, min, max) {
  return {
    name: name,
    type: 'number',
    required: true,
    onlyInt: true,
    min: min,
    max: max,
  };
}

function flag(name) {
  return { name: name, type: 'bool' };
}

function row(app, collection, data) {
  const record = new Record(collection);
  for (const key of Object.keys(data)) {
    record.set(key, data[key]);
  }
  app.save(record);
  return record;
}

function account(app, users, data) {
  const record = new Record(users);
  record.set('email', data.email);
  record.set('emailVisibility', true);
  record.set('verified', true);
  record.set('password', data.password);
  record.set('passwordConfirm', data.password);
  record.set('fullName', data.fullName);
  record.set('username', data.username);
  record.set('role', data.role);
  record.set('code', data.code);
  app.save(record);
  return record;
}
