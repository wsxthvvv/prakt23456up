import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/domain/order_quote.dart';

void main() {
  test('скидка карты уменьшает сумму заказа', () {
    final totals = priceOrder(const [
      PricedLine(
        unitPriceRub: 1000,
        qty: 2,
        weightGrams: 500,
        workshopCode: 1,
      ),
    ], 10);
    expect(totals.subtotalRub, 2000);
    expect(totals.discountRub, 200);
    expect(totals.totalRub, 1800);
  });

  test('нулевая скидка оставляет полную сумму', () {
    final totals = priceOrder(const [
      PricedLine(
        unitPriceRub: 220,
        qty: 3,
        weightGrams: 90,
        workshopCode: 1,
      ),
    ], 0);
    expect(totals.totalRub, 660);
    expect(totals.discountRub, 0);
  });

  test('скидка не бывает больше 90 процентов', () {
    final totals = priceOrder(const [
      PricedLine(
        unitPriceRub: 100,
        qty: 1,
        weightGrams: 100,
        workshopCode: 1,
      ),
    ], 150);
    expect(totals.discountPercent, 90);
    expect(totals.totalRub, 10);
  });

  test('пустой заказ стоит ноль', () {
    final totals = priceOrder(const [], 10);
    expect(totals.totalRub, 0);
  });

  test('цех перегружен, если новая масса больше суточной мощности', () {
    final loads = workshopLoads(
      lines: const [
        PricedLine(
          unitPriceRub: 1890,
          qty: 4,
          weightGrams: 1200,
          workshopCode: 1,
        ),
      ],
      alreadyGrams: const {1: 4000},
      capacityGrams: const {1: 8},
    );
    expect(loads.single.overloaded, isTrue);
    expect(overloadMessage(loads), contains('Цех не успеет'));
  });

  test('заказ проходит, если мощность цеха ещё не выбрана', () {
    final loads = workshopLoads(
      lines: const [
        PricedLine(
          unitPriceRub: 220,
          qty: 2,
          weightGrams: 90,
          workshopCode: 2,
        ),
      ],
      alreadyGrams: const {2: 1000},
      capacityGrams: const {2: 5},
    );
    expect(loads.single.overloaded, isFalse);
    expect(overloadMessage(loads), isNull);
  });

  test('масса суммируется по каждому цеху отдельно', () {
    final loads = workshopLoads(
      lines: const [
        PricedLine(
          unitPriceRub: 100,
          qty: 1,
          weightGrams: 1000,
          workshopCode: 1,
        ),
        PricedLine(
          unitPriceRub: 100,
          qty: 1,
          weightGrams: 500,
          workshopCode: 1,
        ),
        PricedLine(
          unitPriceRub: 100,
          qty: 1,
          weightGrams: 200,
          workshopCode: 2,
        ),
      ],
      alreadyGrams: const {},
      capacityGrams: const {1: 2, 2: 2},
    );
    expect(loads.length, 2);
    final first = loads.firstWhere((item) => item.workshopCode == 1);
    expect(first.addGrams, 1500);
    expect(first.overloaded, isFalse);
  });

  test('отрицательная скидка считается как ноль', () {
    final totals = priceOrder(const [
      PricedLine(
        unitPriceRub: 500,
        qty: 1,
        weightGrams: 100,
        workshopCode: 1,
      ),
    ], -5);
    expect(totals.discountPercent, 0);
    expect(totals.totalRub, 500);
  });
}
