/// Если клиент не прислал номер записи, берём следующий свободный.
onRecordCreate(
  (e) => {
    if (!e.record.getInt('code')) {
      const name = e.record.collection().name;
      let next = 1;
      try {
        const rows = e.app.findRecordsByFilter(name, 'code >= 1', '-code', 1, 0);
        if (rows.length > 0) {
          next = rows[0].getInt('code') + 1;
        }
      } catch (error) {
        void error;
      }
      e.record.set('code', next);
    }
    e.next();
  },
  'flavors',
  'categories',
  'workshops',
  'confectioners',
  'products',
  'customers',
  'loyalty_cards',
  'orders',
  'order_lines',
  'users',
);
