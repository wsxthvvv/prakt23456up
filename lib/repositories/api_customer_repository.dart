import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/json_values.dart';
import '../core/pb_links.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/loyalty_card.dart';
import '../models/page_result.dart';
import 'customer_repository.dart';
import 'remote_collection.dart';

class _StoredCard {
  _StoredCard(this.pbId, this.card);
  final String pbId;
  final LoyaltyCard card;
}

class ApiCustomerRepository implements CustomerRepository {
  ApiCustomerRepository(this._dio, {PbLinks? links})
    : _links = links ?? PbLinks.shared {
    _remote = RemoteCollection<Customer>(
      dio: _dio,
      resource: 'customers',
      links: _links,
      decode: _decode,
      encode: _write,
      idOf: (item) => item.id,
      hints: const PbHints(
        searchFields: ['lastName', 'firstName', 'email', 'phone'],
      ),
    );
  }

  final Dio _dio;
  final PbLinks _links;
  late final RemoteCollection<Customer> _remote;
  final Map<int, _StoredCard> _cards = {};
  final Map<String, _StoredCard> _cardsByCustomer = {};

  Future<void> warm() async {
    await _loadCards();
    await _remote.warm();
  }

  @override
  List<Customer> get all => _remote.all;

  @override
  Future<PageResult<Customer>> find(CustomerQuery query) async {
    await _loadCards();
    return _remote.find({
      if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
      if (_cardFilter(query.cardActive) != null)
        'filter': _cardFilter(query.cardActive),
      'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
      'page': query.page,
      'size': query.size,
      if (query.includeDeleted) 'includeDeleted': true,
    });
  }

  @override
  Future<Customer?> findById(int id) => _remote.findById(id);

  @override
  Future<Customer> create(Customer customer) async {
    final saved = await _remote.create(customer);
    await _saveCard(saved.id, customer.loyaltyCard);
    return _withCard(saved);
  }

  @override
  Future<Customer> update(Customer customer) async {
    final saved = await _remote.update(customer);
    await _saveCard(saved.id, customer.loyaltyCard);
    return _withCard(saved);
  }

  @override
  Future<void> softDelete(int id) => _remote.softDelete(id);

  @override
  Future<void> hardDelete(int id) async {
    await _remote.hardDelete(id);
    _cards.remove(id);
  }

  @override
  Future<void> restore(int id) => _remote.restore(id);

  @override
  Future<int> deleteMany(List<int> ids) => _remote.deleteMany(ids);

  @override
  bool emailExists(String email, {int? exceptId}) {
    final needle = email.trim().toLowerCase();
    return _remote.cache.any(
      (item) => item.id != exceptId && item.email.toLowerCase() == needle,
    );
  }

  Customer _decode(Map<String, dynamic> json) {
    final code = jsonInt(json['id']);
    final stored =
        _cards[code] ?? _cardsByCustomer[jsonString(json['pbId'])];
    final card =
        stored?.card ??
        const LoyaltyCard(
          number: '',
          issuedOn: '',
          discountPercent: 0,
          active: false,
        );
    return Customer.fromJson({...json, 'loyaltyCard': card.toJson()});
  }

  Customer _withCard(Customer customer) {
    final card = _cards[customer.id]?.card ?? customer.loyaltyCard;
    return customer.copyWith(loyaltyCard: card);
  }

  String? _cardFilter(bool? active) {
    if (active == null) return null;
    final codes = [
      for (final entry in _cards.entries)
        if (entry.value.card.active == active) entry.key,
    ];
    if (codes.isEmpty) return 'code = 0';
    return '(${codes.map((code) => 'code = $code').join(' || ')})';
  }

  Future<void> _loadCards() => guard(() async {
    _cards.clear();
    _cardsByCustomer.clear();
    final response = await _dio.get(
      '/collections/loyalty_cards/records',
      queryParameters: {
        'page': 1,
        'perPage': 200,
        'expand': 'customer',
        'filter': 'deleted = false',
      },
    );
    final data = response.data;
    final items = data is Map && data['items'] is List
        ? data['items'] as List
        : const [];
    for (final item in items) {
      if (item is! Map) continue;
      final row = Map<String, dynamic>.from(item);
      final expand = row['expand'];
      final customer = expand is Map ? expand['customer'] : null;
      final customerCode = customer is Map ? jsonInt(customer['code']) : 0;
      final customerPb = jsonString(
        customer is Map ? customer['id'] : row['customer'],
      );
      final stored = _StoredCard(
        jsonString(row['id']),
        LoyaltyCard(
          number: jsonString(row['number']),
          issuedOn: jsonString(row['issuedOn']).split(' ').first,
          discountPercent: jsonInt(row['discountPercent']),
          active: jsonBool(row['active']),
        ),
      );
      if (customerCode > 0) {
        _links.remember('customers', customerCode, customerPb);
        _cards[customerCode] = stored;
      }
      if (customerPb.isNotEmpty) _cardsByCustomer[customerPb] = stored;
      _links.remember(
        'loyalty_cards',
        jsonInt(row['code']),
        jsonString(row['id']),
      );
    }
  });

  Future<void> _saveCard(int customerCode, LoyaltyCard card) => guard(() async {
    final customerPb = _links.pbId('customers', customerCode);
    if (customerPb == null) return;
    final stored = _cards[customerCode];
    final body = {
      'customer': customerPb,
      'number': card.number,
      'issuedOn': card.issuedOn.contains('T') || card.issuedOn.contains(' ')
          ? card.issuedOn
          : '${card.issuedOn} 00:00:00.000Z',
      'discountPercent': card.discountPercent,
      'active': card.active,
      'deleted': false,
    };
    final Response<dynamic> response;
    if (stored == null) {
      body['code'] = _links.nextCode('loyalty_cards');
      response = await _dio.post(
        '/collections/loyalty_cards/records',
        data: body,
      );
    } else {
      response = await _dio.patch(
        '/collections/loyalty_cards/records/${stored.pbId}',
        data: body,
      );
    }
    final saved = response.data;
    if (saved is Map) {
      final row = Map<String, dynamic>.from(saved);
      _links.remember(
        'loyalty_cards',
        jsonInt(row['code']),
        jsonString(row['id']),
      );
      final stored = _StoredCard(jsonString(row['id']), card);
      _cards[customerCode] = stored;
      _cardsByCustomer[customerPb] = stored;
    }
  });
}

Map<String, dynamic> _write(Customer item) => {
  'lastName': item.lastName,
  'firstName': item.firstName,
  'email': item.email,
  'phone': item.phone,
};
