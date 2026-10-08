import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/core/api_client.dart';
import 'package:prakt2up/core/api_exceptions.dart';
import 'package:prakt2up/models/product.dart';
import 'package:prakt2up/models/product_query.dart';
import 'package:prakt2up/repositories/api_product_repository.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio _dio(Future<ResponseBody> Function(RequestOptions options) respond) {
  final dio = buildDio();
  dio.httpClientAdapter = _ScriptedAdapter(respond);
  return dio;
}

void main() {
  const draft = Product(
    id: 0,
    name: 'Прага',
    sku: 'NYM-020',
    year: 2019,
    weightGrams: 1000,
    categoryId: 1,
    workshopId: 1,
    confectionerIds: [1],
    flavorTagIds: [1],
    stockTotal: 22,
    stockAvailable: 9,
  );

  test('find reads one server page and keeps the query', () async {
    RequestOptions? seen;
    final repo = ApiProductRepository(
      _dio((options) async {
        seen = options;
        return _json(200, {
          'items': [
            {
              'id': 'rec20',
              'code': 20,
              'name': 'Торт «Прага»',
              'sku': 'NYM-020',
              'year': 2019,
              'weightGrams': 1000,
              'stockTotal': 22,
              'stockAvailable': 9,
              'deleted': false,
              'expand': {
                'category': {'id': 'cat1', 'code': 1, 'name': 'Торты'},
                'workshop': {'id': 'ws1', 'code': 1, 'name': 'Цех тортов'},
                'confectioners': [
                  {'id': 'cf1', 'code': 1},
                ],
                'flavors': [
                  {'id': 'fl1', 'code': 1, 'name': 'Шоколад'},
                ],
              },
            },
          ],
          'page': 2,
          'perPage': 10,
          'totalItems': 30,
          'totalPages': 3,
        });
      }),
    );

    final page = await repo.find(const ProductQuery(search: 'прага', page: 2));

    expect(page.page, 2);
    expect(page.total, 30);
    expect(page.items, hasLength(1));
    expect(page.items.single.categoryId, 1);
    expect(page.items.single.workshopId, 1);
    expect(page.items.single.confectionerIds, [1]);
    expect(page.items.single.flavorTagIds, [1]);
    expect(seen?.queryParameters['page'], 2);
    expect('${seen?.queryParameters['filter']}', contains('прага'));
    expect(seen?.path, '/collections/products/records');
  });

  test('create returns the product assigned by the server', () async {
    final repo = ApiProductRepository(
      _dio((options) async {
        return _json(201, {
          'id': 'rec31',
          'code': 31,
          'name': 'Прага',
          'sku': 'NYM-031',
          'year': 2019,
          'weightGrams': 1000,
          'stockTotal': 22,
          'stockAvailable': 9,
          'deleted': false,
          'expand': {
            'category': {'id': 'cat1', 'code': 1},
            'workshop': {'id': 'ws1', 'code': 1},
            'confectioners': [
              {'id': 'cf1', 'code': 1},
            ],
            'flavors': [
              {'id': 'fl1', 'code': 1},
            ],
          },
        });
      }),
    );

    final created = await repo.create(draft.copyWith(sku: 'NYM-031'));
    expect(created.id, 31);
    expect(created.sku, 'NYM-031');
  });

  test('http 422 becomes a field validation error', () async {
    final repo = ApiProductRepository(
      _dio((options) async {
        return _json(422, {
          'message': 'Ошибка валидации',
          'errors': {'sku': 'Изделие с таким артикулом уже существует'},
        });
      }),
    );

    expect(
      () => repo.create(draft),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.errors['sku'],
          'sku',
          'Изделие с таким артикулом уже существует',
        ),
      ),
    );
  });

  test('unreachable server becomes NetworkException', () async {
    final repo = ApiProductRepository(
      _dio((options) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }),
    );

    await expectLater(
      repo.find(const ProductQuery()),
      throwsA(isA<NetworkException>()),
    );
  });

  test('http 409 becomes ConflictException', () async {
    final repo = ApiProductRepository(
      _dio((options) async {
        return _json(409, {
          'message': 'На выбранные цеха ссылаются изделия: 9. Сначала смените цех у этих записей.',
        });
      }),
    );

    expect(
      () => repo.hardDelete(1),
      throwsA(
        isA<ConflictException>().having(
          (error) => error.message,
          'message',
          contains('изделия'),
        ),
      ),
    );
  });
}
