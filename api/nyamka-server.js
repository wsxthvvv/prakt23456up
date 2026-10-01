#!/usr/bin/env node
'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', 8080));
const ORIGIN = arg('origin', '*');
const SECRET = 'нямка-учебный-ключ';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;
const ROLE_LEVEL = { buyer: 1, seller: 2, admin: 3 };

let db;

function b64url(value) {
  return Buffer.from(value).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  try {
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (payload.exp && payload.exp * 1000 < Date.now()) return null;
    return payload;
  } catch {
    return null;
  }
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const row = { id: db.seq[collection], ...obj, createdAt: new Date().toISOString(), deletedAt: null };
  db[collection].push(row);
  return row.id;
}

function seed() {
  db = {
    seq: {},
    categories: [],
    flavors: [],
    workshops: [],
    confectioners: [],
    products: [],
    customers: [],
    users: [],
    refreshTokens: new Set(),
  };

  const categories = ['Торты', 'Пирожные', 'Печенье', 'Хлеб сладкий', 'Десерты в стаканчиках'];
  categories.forEach((name) => push('categories', { name }));

  const flavorRows = [
    ['Шоколад', 'Какао и тёмный шоколад', 5],
    ['Ваниль', 'Классическая ваниль', 2],
    ['Ягоды', 'Ягодные начинки', 4],
    ['Орехи', 'Миндаль, фундук и грецкий орех', 3],
    ['Карамель', 'Солёная и молочная карамель', 4],
    ['Цитрус', 'Лимон, апельсин, цедра', 3],
    ['Мята', 'Свежая мята', 2],
    ['Кофе', 'Эспрессо и какао-бобы', 5],
    ['Кокос', 'Кокосовая стружка и молоко', 3],
    ['Пряности', 'Корица, кардамон, имбирь', 4],
    ['Фисташка', 'Фисташковая паста', 4],
    ['Малина', 'Малиновое пюре', 3],
  ];
  flavorRows.forEach(([name, description, intensity]) => push('flavors', { name, description, intensity }));

  const workshopRows = [
    ['Цех тортов', 'Москва', '+74951110001', [1, 2, 3, 4, 11]],
    ['Цех пирожных', 'Москва', '+74951110002', [1, 2, 3, 5, 6]],
    ['Цех выпечки', 'Санкт-Петербург', '+78121110003', [1, 2, 4, 5, 10]],
    ['Цех десертов', 'Казань', '+78431110004', [1, 2, 3, 7, 8]],
    ['Цех дегустаций', 'Тула', '+74872110005', [2, 12]],
    ['Цех глазури', 'Москва', '+74951110006', [1, 5]],
    ['Цех карамели', 'Тула', '+74872110007', [5, 10]],
    ['Цех теста', 'Казань', '+78431110008', [2, 4]],
    ['Цех оформления', 'Санкт-Петербург', '+78121110009', [3, 6]],
    ['Цех сезонный', 'Сочи', '+78621110010', [3, 12]],
    ['Цех ночной', 'Москва', '+74951110011', [8, 9]],
  ];
  workshopRows.forEach(([name, city, phone, flavorIds]) => push('workshops', { name, city, phone, flavorIds }));

  const chefs = [
    ['Иванова', 'Мария', 'Россия', 'Торты', 1],
    ['Петров', 'Алексей', 'Россия', 'Пирожные', 2],
    ['Дюмонова', 'Клара', 'Франция', 'Десерты', 4],
    ['Романов', 'Лука', 'Италия', 'Выпечка', 3],
    ['Смирнова', 'Елена', 'Россия', 'Торты', 1],
    ['Бернардова', 'Анна', 'Бельгия', 'Шоколад', 3],
    ['Козлова', 'Анна', 'Россия', 'Пирожные', 2],
    ['Мартинова', 'Софья', 'Франция', 'Десерты', 4],
    ['Волков', 'Дмитрий', 'Россия', 'Выпечка', 3],
    ['Бянкова', 'Юлия', 'Италия', 'Торты', 1],
  ];
  chefs.forEach(([lastName, firstName, country, specialty, workshopId]) =>
    push('confectioners', { lastName, firstName, country, specialty, workshopId }));

  const products = [
    ['Наполеон классический', 'NYM-001', 2019, 1200, 1, 1, [1, 5], [2, 4], 20, 12],
    ['Медовик с кремом', 'NYM-002', 2020, 900, 1, 1, [1], [2], 15, 8],
    ['Эклер шоколадный', 'NYM-003', 2021, 80, 2, 2, [2, 7], [1], 100, 64],
    ['Макарон ассорти', 'NYM-004', 2022, 120, 2, 2, [2], [1, 3], 80, 45],
    ['Круассан миндальный', 'NYM-005', 2023, 70, 4, 3, [4, 9], [4], 60, 22],
    ['Тирамису в стакане', 'NYM-006', 2024, 150, 5, 4, [3, 8], [1, 2], 40, 18],
    ['Панна-котта ягодная', 'NYM-007', 2023, 130, 5, 4, [8], [3], 35, 20],
    ['Печенье овсяное', 'NYM-008', 2019, 200, 3, 3, [9], [4], 120, 90],
    ['Брауни ореховый', 'NYM-009', 2020, 90, 3, 3, [6], [1, 4], 70, 33],
    ['Красный бархат', 'NYM-010', 2021, 1500, 1, 1, [5, 10], [3], 12, 5],
    ['Чизкейк классический', 'NYM-011', 2022, 1100, 1, 1, [10], [2], 18, 11],
    ['Профитроль с карамелью', 'NYM-012', 2023, 60, 2, 2, [2], [5], 90, 55],
    ['Багет с изюмом', 'NYM-013', 2024, 350, 4, 3, [4], [2], 25, 14],
    ['Тарт с лимоном', 'NYM-014', 2020, 400, 2, 2, [7], [3], 30, 16],
    ['Кекс шоколадный', 'NYM-015', 2021, 110, 3, 3, [6, 9], [1], 85, 40],
    ['Павлова с ягодами', 'NYM-016', 2022, 500, 1, 1, [5], [3], 10, 4],
    ['Канеле бордо', 'NYM-017', 2023, 50, 2, 2, [2], [5], 55, 28],
    ['Булочка с корицей', 'NYM-018', 2024, 180, 4, 3, [9], [2, 5], 45, 30],
    ['Мусс с манго', 'NYM-019', 2023, 140, 5, 4, [8], [3], 32, 19],
    ['Торт «Прага»', 'NYM-020', 2019, 1000, 1, 1, [1, 5], [1], 22, 9],
    ['Печенье с миндалем', 'NYM-021', 2022, 160, 3, 3, [4], [4], 65, 42],
    ['Торт три шоколада', 'NYM-022', 2024, 1300, 1, 1, [5, 10], [1], 14, 7],
    ['Зефир ванильный', 'NYM-023', 2020, 850, 1, 1, [1], [2], 16, 10],
    ['Крем-брюле в коробке', 'NYM-024', 2021, 95, 2, 2, [7], [2], 75, 48],
    ['Ролл с корицей', 'NYM-025', 2022, 85, 4, 3, [9], [4], 50, 35],
    ['Вафля бельгийская', 'NYM-026', 2023, 65, 3, 3, [6], [1], 90, 52],
    ['Меренговый тарт', 'NYM-027', 2024, 980, 1, 1, [5], [3], 11, 6],
    ['Париж с клубникой', 'NYM-028', 2019, 140, 2, 2, [2], [5], 60, 38],
    ['Суфле вишневый', 'NYM-029', 2022, 720, 1, 1, [10], [3], 13, 8],
    ['Крем-брюле клубничка', 'NYM-030', 2024, 55, 5, 4, [3, 8], [2], 48, 31],
  ];
  products.forEach(([name, sku, year, weightGrams, categoryId, workshopId, confectionerIds, flavorTagIds, stockTotal, stockAvailable]) =>
    push('products', { name, sku, year, weightGrams, categoryId, workshopId, confectionerIds, flavorTagIds, stockTotal, stockAvailable }));

  const customers = [
    ['Соколова', 'Анна', 'anna.sokolova@nyamka.test', '+79001000001', 'NY-100001', '2024-01-15', 5, true],
    ['Орлов', 'Игорь', 'igor.orlov@nyamka.test', '+79001000002', 'NY-100002', '2024-02-02', 10, true],
    ['Морозова', 'Дарья', 'darya.morozova@nyamka.test', '+79001000003', 'NY-100003', '2023-11-20', 0, true],
    ['Лебедев', 'Павел', 'pavel.lebedev@nyamka.test', '+79001000004', 'NY-100004', '2024-03-08', 15, true],
    ['Кузнецова', 'Ольга', 'olga.kuznetsova@nyamka.test', '+79001000005', 'NY-100005', '2024-04-12', 7, true],
    ['Новиков', 'Сергей', 'sergey.novikov@nyamka.test', '+79001000006', 'NY-100006', '2023-09-01', 20, true],
    ['Павлова', 'Ирина', 'irina.pavlova@nyamka.test', '+79001000007', 'NY-100007', '2024-05-19', 3, true],
    ['Федоров', 'Никита', 'nikita.fedorov@nyamka.test', '+79001000008', 'NY-100008', '2024-06-03', 12, true],
    ['Белова', 'Марина', 'marina.belova@nyamka.test', '+79001000009', 'NY-100009', '2023-12-25', 8, true],
    ['Громов', 'Артём', 'artem.gromov@nyamka.test', '+79001000010', 'NY-100010', '2024-07-14', 25, true],
    ['Егорова', 'Светлана', 'svetlana.egorova@nyamka.test', '+79001000011', 'NY-100011', '2024-08-09', 4, true],
    ['Зайцев', 'Кирилл', 'kirill.zaitsev@nyamka.test', '+79001000012', 'NY-100012', '2022-10-30', 0, false],
  ];
  customers.forEach(([lastName, firstName, email, phone, number, issuedOn, discountPercent, active]) =>
    push('customers', { lastName, firstName, email, phone, loyaltyCard: { number, issuedOn, discountPercent, active } }));

  push('users', { username: 'admin', passwordHash: hash('admin123'), fullName: 'Администратор', email: 'admin@nyamka.test', role: 'admin' });
  push('users', { username: 'seller', passwordHash: hash('seller123'), fullName: 'Продавец зала', email: 'seller@nyamka.test', role: 'seller' });
  push('users', { username: 'buyer', passwordHash: hash('buyer123'), fullName: 'Соколова Анна', email: 'anna.sokolova@nyamka.test', role: 'buyer' });
}

function byId(collection, id) {
  return db[collection].find((row) => row.id === Number(id));
}

function alive(collection) {
  return db[collection].filter((row) => !row.deletedAt);
}

function presentProduct(row) {
  const category = byId('categories', row.categoryId);
  const workshop = byId('workshops', row.workshopId);
  return {
    ...row,
    category: category ? { id: category.id, name: category.name } : null,
    workshop: workshop ? { id: workshop.id, name: workshop.name } : null,
    confectioners: row.confectionerIds
      .map((id) => byId('confectioners', id))
      .filter(Boolean)
      .map((item) => ({ id: item.id, fullName: item.lastName + ' ' + item.firstName })),
    flavors: row.flavorTagIds
      .map((id) => byId('flavors', id))
      .filter(Boolean)
      .map((item) => ({ id: item.id, name: item.name })),
  };
}

function presentConfectioner(row) {
  const workshop = byId('workshops', row.workshopId);
  return { ...row, workshop: workshop ? { id: workshop.id, name: workshop.name } : null };
}

function presentWorkshop(row) {
  return {
    ...row,
    flavors: row.flavorIds
      .map((id) => byId('flavors', id))
      .filter(Boolean)
      .map((item) => ({ id: item.id, name: item.name })),
  };
}

const present = {
  products: presentProduct,
  confectioners: presentConfectioner,
  workshops: presentWorkshop,
  flavors: (row) => row,
  customers: (row) => row,
  categories: (row) => ({ id: row.id, name: row.name }),
};

function pageOf(rows, query, presentRow) {
  const page = Math.max(1, Number(query.page) || 1);
  const size = Math.min(100, Math.max(1, Number(query.size) || 10));
  const total = rows.length;
  const from = (page - 1) * size;
  return {
    items: rows.slice(from, from + size).map(presentRow),
    page,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size) || 1),
  };
}

function sortRows(rows, query, valueOf) {
  const [field, dir] = String(query.sort || 'id,asc').split(',');
  const sign = dir === 'desc' ? -1 : 1;
  return rows.slice().sort((a, b) => {
    const left = valueOf(a, field);
    const right = valueOf(b, field);
    return String(left).localeCompare(String(right), 'ru', { numeric: true, sensitivity: 'base' }) * sign;
  });
}

function includes(query) {
  return query.includeDeleted === 'true';
}

function text(value) {
  return String(value || '').trim().toLowerCase();
}

function str(value) {
  return String(value || '').trim();
}

function ids(value) {
  if (!Array.isArray(value)) return [];
  return value.map(Number).filter((id) => Number.isInteger(id) && id > 0);
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}

function send(res, status, payload) {
  cors(res);
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message, errors) {
  if (errors) return send(res, status, { message, errors });
  return send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers.authorization || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((user) => user.id === payload.sub && !user.deletedAt) || null;
}

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if ((ROLE_LEVEL[user.role] || 0) < ROLE_LEVEL[minRole]) {
    fail(res, 403, 'Недостаточно прав для этого действия.');
    return false;
  }
  return true;
}

function publicUser(user) {
  return { id: user.id, username: user.username, fullName: user.fullName, email: user.email, role: user.role };
}

function issueTokens(user) {
  const now = Math.floor(Date.now() / 1000);
  const accessToken = sign({ sub: user.id, role: user.role, type: 'access', exp: now + ACCESS_TTL });
  const refreshToken = sign({ sub: user.id, role: user.role, type: 'refresh', exp: now + REFRESH_TTL });
  db.refreshTokens.add(refreshToken);
  return {
    accessToken,
    refreshToken,
    expiresIn: ACCESS_TTL,
    user: publicUser(user),
  };
}

function linkedProducts(workshopId) {
  return alive('products').filter((item) => item.workshopId === workshopId).length;
}

function validateProduct(body, exceptId) {
  const errors = {};
  const name = str(body.name);
  const sku = str(body.sku);
  const year = Number(body.year);
  const weight = Number(body.weightGrams);
  const stockTotal = Number(body.stockTotal);
  const stockAvailable = Number(body.stockAvailable);
  if (name.length < 2) errors.name = 'Укажите название';
  if (sku.length < 3) errors.sku = 'Укажите артикул';
  else if (alive('products').some((item) => item.id !== exceptId && item.sku.toLowerCase() === sku.toLowerCase())) {
    errors.sku = 'Изделие с таким артикулом уже существует';
  }
  if (!Number.isInteger(year) || year < 1990) errors.year = 'Укажите год';
  else if (year > new Date().getFullYear()) errors.year = 'Год не может быть больше текущего';
  if (!Number.isInteger(weight) || weight < 1) errors.weightGrams = 'Укажите массу';
  if (!byId('categories', body.categoryId)) errors.categoryId = 'Выберите категорию';
  if (!byId('workshops', body.workshopId) || byId('workshops', body.workshopId).deletedAt) errors.workshopId = 'Выберите цех';
  if (!Number.isInteger(stockTotal) || stockTotal < 1) errors.stockTotal = 'Укажите количество';
  if (!Number.isInteger(stockAvailable) || stockAvailable < 0) errors.stockAvailable = 'Укажите доступный остаток';
  else if (Number.isInteger(stockTotal) && stockAvailable > stockTotal) errors.stockAvailable = 'Доступно не больше, чем на складе';
  return errors;
}

function validateCustomer(body, exceptId) {
  const errors = {};
  const email = str(body.email).toLowerCase();
  if (str(body.lastName).length < 2) errors.lastName = 'Укажите фамилию';
  if (str(body.firstName).length < 2) errors.firstName = 'Укажите имя';
  if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) errors.email = 'Некорректный адрес почты';
  else if (alive('customers').some((item) => item.id !== exceptId && item.email.toLowerCase() === email)) {
    errors.email = 'Покупатель с такой почтой уже существует';
  }
  const card = body.loyaltyCard || {};
  if (str(card.number).length < 3) errors['loyaltyCard.number'] = 'Укажите номер карты';
  return errors;
}

function productBody(body) {
  return {
    name: str(body.name),
    sku: str(body.sku),
    year: Number(body.year),
    weightGrams: Number(body.weightGrams),
    categoryId: Number(body.categoryId),
    workshopId: Number(body.workshopId),
    confectionerIds: ids(body.confectionerIds),
    flavorTagIds: ids(body.flavorTagIds),
    stockTotal: Number(body.stockTotal),
    stockAvailable: Number(body.stockAvailable),
  };
}

const resources = {
  products: {
    search(row, query) {
      const needle = text(query.search);
      if (needle && !text(row.name).includes(needle) && !text(row.sku).includes(needle)) return false;
      if (query.categoryId && row.categoryId !== Number(query.categoryId)) return false;
      if (query.flavorTagId && !row.flavorTagIds.includes(Number(query.flavorTagId))) return false;
      if (query.yearFrom && row.year < Number(query.yearFrom)) return false;
      if (query.yearTo && row.year > Number(query.yearTo)) return false;
      return true;
    },
    sort(row, field) {
      return row[field] ?? row.name;
    },
  },
  confectioners: {
    search(row, query) {
      const needle = text(query.search);
      const full = text(row.lastName + ' ' + row.firstName);
      if (needle && !full.includes(needle)) return false;
      if (query.country && row.country !== query.country) return false;
      if (query.specialty && row.specialty !== query.specialty) return false;
      return true;
    },
    sort(row, field) {
      return row[field] ?? row.lastName;
    },
  },
  flavors: {
    search(row, query) {
      const needle = text(query.search);
      if (needle && !text(row.name).includes(needle) && !text(row.description).includes(needle)) return false;
      if (query.intensity && row.intensity !== Number(query.intensity)) return false;
      return true;
    },
    sort(row, field) {
      return row[field] ?? row.name;
    },
  },
  workshops: {
    search(row, query) {
      const needle = text(query.search);
      if (needle && !text(row.name).includes(needle) && !text(row.city).includes(needle) && !text(row.phone).includes(needle)) return false;
      if (query.city && row.city !== query.city) return false;
      return true;
    },
    sort(row, field) {
      return row[field] ?? row.name;
    },
  },
  customers: {
    search(row, query) {
      const needle = text(query.search);
      const full = text(row.lastName + ' ' + row.firstName + ' ' + row.email + ' ' + row.phone);
      if (needle && !full.includes(needle)) return false;
      if (query.cardActive === 'true' && !row.loyaltyCard.active) return false;
      if (query.cardActive === 'false' && row.loyaltyCard.active) return false;
      return true;
    },
    sort(row, field) {
      if (field === 'email') return row.email;
      return row[field] ?? row.lastName;
    },
  },
  categories: {
    search() {
      return true;
    },
    sort(row, field) {
      return row[field] ?? row.name;
    },
  },
};

function listResource(name, query) {
  const spec = resources[name];
  let rows = db[name].filter((row) => includes(query) || !row.deletedAt);
  rows = rows.filter((row) => spec.search(row, query));
  rows = sortRows(rows, query, spec.sort);
  return pageOf(rows, query, present[name]);
}

function workshopConflict(res, id) {
  const total = linkedProducts(id);
  if (!total) return false;
  fail(res, 409, 'На выбранные цеха ссылаются изделия: ' + total + '. Сначала смените цех у этих записей.');
  return true;
}

async function handle(req, res, url) {
  const query = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();

  if (query.__fail) {
    return fail(res, Number(query.__fail) || 500, 'Ошибка вызвана намеренно параметром __fail');
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', service: 'nyamka', time: new Date().toISOString() });
  }
  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  const user = currentUser(req);

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const found = db.users.find((item) => item.username === str(body.username) && item.passwordHash === hash(String(body.password || '')));
    if (!found) return fail(res, 401, 'Неверный логин или пароль');
    return send(res, 200, issueTokens(found));
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    db.refreshTokens.delete(token);
    const found = db.users.find((item) => item.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');
    return send(res, 200, issueTokens(found));
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!requireRole(res, user, 'buyer')) return;
    return send(res, 200, publicUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204, {});
  }

  if (path === '/api/countries' && method === 'GET') {
    const items = ['Россия', 'Франция', 'Италия', 'Бельгия'];
    return send(res, 200, { items, page: 1, size: items.length, total: items.length, totalPages: 1 });
  }
  if (path === '/api/specialties' && method === 'GET') {
    const items = ['Торты', 'Пирожные', 'Десерты', 'Выпечка', 'Шоколад'];
    return send(res, 200, { items, page: 1, size: items.length, total: items.length, totalPages: 1 });
  }

  const match = path.match(/^\/api\/(products|confectioners|flavors|workshops|customers|categories)(?:\/(\d+))?(?:\/(restore|bulk-delete))?$/);
  const bulk = path.match(/^\/api\/(products|confectioners|flavors|workshops|customers)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    if (!requireRole(res, user, 'seller')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const name = bulk[1];
    const selected = ids(body.ids);
    if (name === 'workshops' && selected.some((id) => linkedProducts(id) > 0)) {
      const total = selected.reduce((sum, id) => sum + linkedProducts(id), 0);
      return fail(res, 409, 'На выбранные цеха ссылаются изделия: ' + total + '. Сначала смените цех у этих записей.');
    }
    let deleted = 0;
    selected.forEach((id) => {
      const row = byId(name, id);
      if (row && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    });
    return send(res, 200, { deleted });
  }

  if (!match) return fail(res, 404, 'Адрес не найден');
  const name = match[1];
  const id = match[2] ? Number(match[2]) : null;
  const action = match[3];

  if (method === 'GET' && !id) return send(res, 200, listResource(name, query));

  if (method === 'GET' && id) {
    const row = byId(name, id);
    if (!row) return fail(res, 404, 'Запись не найдена.');
    return send(res, 200, present[name](row));
  }

  if (method === 'POST' && action === 'restore' && id) {
    if (!requireRole(res, user, 'admin')) return;
    const row = byId(name, id);
    if (!row) return fail(res, 404, 'Запись не найдена.');
    row.deletedAt = null;
    return send(res, 200, present[name](row));
  }

  if (method === 'POST' && !id) {
    if (name === 'categories') return fail(res, 403, 'Справочник категорий только для чтения.');
    if (!requireRole(res, user, 'seller')) return;
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    if (name === 'products') {
      const errors = validateProduct(body);
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const created = byId(name, push(name, productBody(body)));
      return send(res, 201, present[name](created));
    }
    if (name === 'customers') {
      const errors = validateCustomer(body);
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const card = body.loyaltyCard || {};
      const created = byId(name, push(name, {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        email: str(body.email),
        phone: str(body.phone),
        loyaltyCard: {
          number: str(card.number),
          issuedOn: str(card.issuedOn),
          discountPercent: Number(card.discountPercent) || 0,
          active: Boolean(card.active),
        },
      }));
      return send(res, 201, present[name](created));
    }
    if (name === 'flavors') {
      const errors = {};
      if (str(body.name).length < 2) errors.name = 'Укажите название';
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const created = byId(name, push(name, { name: str(body.name), description: str(body.description), intensity: Number(body.intensity) || 1 }));
      return send(res, 201, created);
    }
    if (name === 'workshops') {
      const errors = {};
      if (str(body.name).length < 2) errors.name = 'Укажите название';
      if (str(body.city).length < 2) errors.city = 'Укажите город';
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const created = byId(name, push(name, { name: str(body.name), city: str(body.city), phone: str(body.phone), flavorIds: ids(body.flavorIds) }));
      return send(res, 201, present[name](created));
    }
    if (name === 'confectioners') {
      const errors = {};
      if (str(body.lastName).length < 2) errors.lastName = 'Укажите фамилию';
      if (!byId('workshops', body.workshopId)) errors.workshopId = 'Выберите цех';
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const created = byId(name, push(name, {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        country: str(body.country),
        specialty: str(body.specialty),
        workshopId: Number(body.workshopId),
      }));
      return send(res, 201, present[name](created));
    }
  }

  if (method === 'PUT' && id) {
    if (!requireRole(res, user, 'seller')) return;
    const row = byId(name, id);
    if (!row || row.deletedAt) return fail(res, 404, 'Запись не найдена.');
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    if (name === 'products') {
      const errors = validateProduct(body, id);
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      Object.assign(row, productBody(body));
      return send(res, 200, present[name](row));
    }
    if (name === 'customers') {
      const errors = validateCustomer(body, id);
      if (Object.keys(errors).length) return fail(res, 422, 'Ошибка валидации', errors);
      const card = body.loyaltyCard || {};
      Object.assign(row, {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        email: str(body.email),
        phone: str(body.phone),
        loyaltyCard: {
          number: str(card.number),
          issuedOn: str(card.issuedOn),
          discountPercent: Number(card.discountPercent) || 0,
          active: Boolean(card.active),
        },
      });
      return send(res, 200, row);
    }
    if (name === 'flavors') {
      Object.assign(row, { name: str(body.name), description: str(body.description), intensity: Number(body.intensity) || 1 });
      return send(res, 200, row);
    }
    if (name === 'workshops') {
      Object.assign(row, { name: str(body.name), city: str(body.city), phone: str(body.phone), flavorIds: ids(body.flavorIds) });
      return send(res, 200, present[name](row));
    }
    if (name === 'confectioners') {
      Object.assign(row, {
        lastName: str(body.lastName),
        firstName: str(body.firstName),
        country: str(body.country),
        specialty: str(body.specialty),
        workshopId: Number(body.workshopId),
      });
      return send(res, 200, present[name](row));
    }
  }

  if (method === 'DELETE' && id) {
    const hard = query.hard === 'true';
    if (!requireRole(res, user, hard ? 'admin' : 'seller')) return;
    const row = byId(name, id);
    if (!row) return fail(res, 404, 'Запись не найдена.');
    if (name === 'workshops' && workshopConflict(res, id)) return;
    if (hard) {
      db[name] = db[name].filter((item) => item.id !== id);
    } else {
      row.deletedAt = new Date().toISOString();
    }
    res.writeHead(204, {
      'Access-Control-Allow-Origin': ORIGIN,
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
    return res.end();
  }

  return fail(res, 404, 'Адрес не найден');
}

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://' + (req.headers.host || 'localhost'));
  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }
  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((resolve) => setTimeout(resolve, Math.min(delay, 10000)));
  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (error) {
    console.error(error);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера');
  }
  console.log(req.method.padEnd(6) + ' ' + url.pathname + url.search + '  → ' + res.statusCode + '  ' + (Date.now() - started) + ' мс');
});

server.listen(PORT, () => {
  console.log('');
  console.log('  Учебное API «нямка»');
  console.log('  Адрес:               http://localhost:' + PORT + '/api');
  console.log('  Проверка:            http://localhost:' + PORT + '/api/__health');
  console.log('  Разрешённый источник: ' + ORIGIN);
  console.log('  Учётные записи:      admin/admin123  seller/seller123  buyer/buyer123');
  console.log('');
});
