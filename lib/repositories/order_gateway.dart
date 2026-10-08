import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../core/pb_links.dart';

class OrderLineView {
  const OrderLineView({
    required this.productCode,
    required this.productName,
    required this.qty,
    required this.unitPriceRub,
    required this.weightGrams,
    required this.workshopCode,
  });

  final int productCode;
  final String productName;
  final int qty;
  final int unitPriceRub;
  final int weightGrams;
  final int workshopCode;
}

class OrderView {
  const OrderView({
    required this.code,
    required this.customerCode,
    required this.customerName,
    required this.dueOn,
    required this.status,
    required this.discountPercent,
    required this.totalRub,
    required this.lines,
  });

  final int code;
  final int customerCode;
  final String customerName;
  final String dueOn;
  final String status;
  final int discountPercent;
  final int totalRub;
  final List<OrderLineView> lines;
}

class OrderDraftLine {
  const OrderDraftLine({required this.productCode, required this.qty});

  final int productCode;
  final int qty;
}

class OrderGateway {
  OrderGateway(this._dio, {PbLinks? links}) : _links = links ?? PbLinks.shared;

  final Dio _dio;
  final PbLinks _links;

  Future<List<OrderView>> list() => guard(() async {
    final orders = await _rows('orders', expand: 'customer');
    final lines = await _rows(
      'order_lines',
      expand: 'product,product.workshop,order',
    );
    final byOrder = <int, List<OrderLineView>>{};
    for (final row in lines) {
      final order = _expand(row, 'order');
      final product = _expand(row, 'product');
      final orderCode = jsonInt(order?['code']);
      if (orderCode <= 0 || product == null) continue;
      final workshop = product['expand'] is Map
          ? (product['expand'] as Map)['workshop']
          : null;
      byOrder.putIfAbsent(orderCode, () => []).add(
        OrderLineView(
          productCode: jsonInt(product['code']),
          productName: jsonString(product['name']),
          qty: jsonInt(row['qty']),
          unitPriceRub: jsonInt(row['unitPriceRub']),
          weightGrams: jsonInt(product['weightGrams']),
          workshopCode: workshop is Map ? jsonInt(workshop['code']) : 0,
        ),
      );
    }
    return [
      for (final row in orders)
        OrderView(
          code: jsonInt(row['code']),
          customerCode: jsonInt(_expand(row, 'customer')?['code']),
          customerName: _customerName(_expand(row, 'customer')),
          dueOn: jsonString(row['dueOn']).split(' ').first,
          status: jsonString(row['status']),
          discountPercent: jsonInt(row['discountPercent']),
          totalRub: jsonInt(row['totalRub']),
          lines: byOrder[jsonInt(row['code'])] ?? const [],
        ),
    ];
  });

  Future<Map<int, int>> gramsOnDate(String dueOn, {int? exceptOrderCode}) async {
    final orders = await list();
    final grams = <int, int>{};
    for (final order in orders) {
      if (order.dueOn != dueOn || order.code == exceptOrderCode) continue;
      if (order.status == 'closed') continue;
      for (final line in order.lines) {
        grams[line.workshopCode] =
            (grams[line.workshopCode] ?? 0) + line.weightGrams * line.qty;
      }
    }
    return grams;
  }

  Future<OrderView> create({
    required int customerCode,
    required String dueOn,
    required int discountPercent,
    required int totalRub,
    required List<OrderDraftLine> lines,
    required Map<int, ({int priceRub, String name})> products,
  }) => guard(() async {
    final customerPb = _links.pbId('customers', customerCode);
    if (customerPb == null) {
      throw const NotFoundException('Покупатель не найден.');
    }
    final orderResponse = await _dio.post(
      '/collections/orders/records',
      data: {
        'code': _links.nextCode('orders'),
        'customer': customerPb,
        'dueOn': _date(dueOn),
        'status': 'open',
        'discountPercent': discountPercent,
        'totalRub': totalRub,
        'note': '',
      },
    );
    final order = _asMap(orderResponse.data);
    _links.remember('orders', jsonInt(order['code']), jsonString(order['id']));
    final views = <OrderLineView>[];
    for (final line in lines) {
      final productPb = _links.pbId('products', line.productCode);
      if (productPb == null) continue;
      final price = products[line.productCode]?.priceRub ?? 0;
      final response = await _dio.post(
        '/collections/order_lines/records',
        data: {
          'code': _links.nextCode('order_lines'),
          'order': order['id'],
          'product': productPb,
          'qty': line.qty,
          'unitPriceRub': price,
        },
      );
      final saved = _asMap(response.data);
      _links.remember(
        'order_lines',
        jsonInt(saved['code']),
        jsonString(saved['id']),
      );
      views.add(
        OrderLineView(
          productCode: line.productCode,
          productName: products[line.productCode]?.name ?? '',
          qty: line.qty,
          unitPriceRub: price,
          weightGrams: 0,
          workshopCode: 0,
        ),
      );
    }
    return OrderView(
      code: jsonInt(order['code']),
      customerCode: customerCode,
      customerName: '',
      dueOn: dueOn,
      status: 'open',
      discountPercent: discountPercent,
      totalRub: totalRub,
      lines: views,
    );
  });

  Future<void> close(int code) => guard(() async {
    final pb = _links.pbId('orders', code);
    if (pb == null) throw const NotFoundException('Заказ не найден.');
    await _dio.patch(
      '/collections/orders/records/$pb',
      data: {'status': 'closed'},
    );
  });

  Future<int?> customerCodeForUser(String pbUserId) => guard(() async {
    if (pbUserId.isEmpty) return null;
    final response = await _dio.get(
      '/collections/customers/records',
      queryParameters: {
        'page': 1,
        'perPage': 1,
        'filter': 'user = ${pbQuote(pbUserId)} && deleted = false',
      },
    );
    final data = _asMap(response.data);
    final items = data['items'];
    if (items is! List || items.isEmpty || items.first is! Map) return null;
    final row = Map<String, dynamic>.from(items.first as Map);
    _links.remember('customers', jsonInt(row['code']), jsonString(row['id']));
    return jsonInt(row['code']);
  });

  Future<List<Map<String, dynamic>>> _rows(
    String collection, {
    required String expand,
  }) async {
    final response = await _dio.get(
      '/collections/$collection/records',
      queryParameters: {
        'page': 1,
        'perPage': 200,
        'sort': '-code',
        'filter': 'deleted = false',
        'expand': expand,
      },
    );
    final data = _asMap(response.data);
    final items = data['items'];
    if (items is! List) return const [];
    final rows = <Map<String, dynamic>>[];
    for (final item in items) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      rows.add(row);
      _links.remember(collection, jsonInt(row['code']), jsonString(row['id']));
      final expanded = row['expand'];
      if (expanded is Map) {
        for (final value in expanded.values) {
          if (value is Map && value['collectionName'] == null) {
            final name = _collectionOf(value);
            if (name != null) {
              _links.remember(name, jsonInt(value['code']), jsonString(value['id']));
            }
          }
        }
      }
    }
    return rows;
  }

  String? _collectionOf(Map value) {
    if (value.containsKey('sku')) return 'products';
    if (value.containsKey('dailyCapacityKg')) return 'workshops';
    if (value.containsKey('lastName') && value.containsKey('email')) {
      return 'customers';
    }
    if (value.containsKey('status')) return 'orders';
    return null;
  }

  Map<String, dynamic>? _expand(Map<String, dynamic> row, String field) {
    final expand = row['expand'];
    if (expand is! Map) return null;
    final value = expand[field];
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _customerName(Map<String, dynamic>? customer) {
    if (customer == null) return '';
    return '${jsonString(customer['lastName'])} ${jsonString(customer['firstName'])}'
        .trim();
  }

  String _date(String day) {
    if (day.contains(' ')) return day;
    return '$day 00:00:00.000Z';
  }
}

Map<String, dynamic> _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const ServerException('Сервер вернул неожиданный ответ.');
}
