/// Расчёт стоимости заказа и проверка, что цех выдержит массу на выбранную дату.
class PricedLine {
  const PricedLine({
    required this.unitPriceRub,
    required this.qty,
    required this.weightGrams,
    required this.workshopCode,
  });

  final int unitPriceRub;
  final int qty;
  final int weightGrams;
  final int workshopCode;

  int get costRub => unitPriceRub * qty;
  int get grams => weightGrams * qty;
}

class OrderTotals {
  const OrderTotals({
    required this.subtotalRub,
    required this.discountPercent,
    required this.discountRub,
    required this.totalRub,
  });

  final int subtotalRub;
  final int discountPercent;
  final int discountRub;
  final int totalRub;
}

class WorkshopLoad {
  const WorkshopLoad({
    required this.workshopCode,
    required this.capacityGrams,
    required this.usedGrams,
    required this.addGrams,
  });

  final int workshopCode;
  final int capacityGrams;
  final int usedGrams;
  final int addGrams;

  bool get overloaded => usedGrams + addGrams > capacityGrams;
}

OrderTotals priceOrder(List<PricedLine> lines, int discountPercent) {
  final subtotal = lines.fold<int>(0, (sum, line) => sum + line.costRub);
  final percent = discountPercent < 0
      ? 0
      : (discountPercent > 90 ? 90 : discountPercent);
  final discount = (subtotal * percent) ~/ 100;
  return OrderTotals(
    subtotalRub: subtotal,
    discountPercent: percent,
    discountRub: discount,
    totalRub: subtotal - discount,
  );
}

List<WorkshopLoad> workshopLoads({
  required List<PricedLine> lines,
  required Map<int, int> alreadyGrams,
  required Map<int, int> capacityGrams,
}) {
  final add = <int, int>{};
  for (final line in lines) {
    add[line.workshopCode] = (add[line.workshopCode] ?? 0) + line.grams;
  }
  return [
    for (final entry in add.entries)
      WorkshopLoad(
        workshopCode: entry.key,
        capacityGrams: (capacityGrams[entry.key] ?? 0) * 1000,
        usedGrams: alreadyGrams[entry.key] ?? 0,
        addGrams: entry.value,
      ),
  ];
}

String? overloadMessage(List<WorkshopLoad> loads) {
  for (final load in loads) {
    if (load.overloaded) {
      final limitKg = load.capacityGrams / 1000;
      final haveKg = (load.usedGrams + load.addGrams) / 1000;
      return 'Цех не успеет: на эту дату уже $haveKg кг при пределе $limitKg кг.';
    }
  }
  return null;
}
