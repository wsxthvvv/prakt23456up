import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/auth/access_policy.dart';
import 'package:prakt2up/core/validators.dart';
import 'package:prakt2up/models/product.dart';

void main() {
  test('required field rejects an empty value', () {
    expect(V.required('Укажите название')(''), 'Укажите название');
    expect(V.required()('   '), isNotNull);
  });

  test('required field accepts text', () {
    expect(V.required('Укажите название')('Наполеон'), isNull);
  });

  test('length stays inside the given bounds', () {
    expect(V.length(min: 2, max: 5)('А'), isNotNull);
    expect(V.length(min: 2, max: 5)('Торт'), isNull);
    expect(V.length(min: 2, max: 5)('Слишком'), isNotNull);
  });

  test('integer validator checks the range', () {
    expect(V.integer(min: 1990, max: 2100)('год'), isNotNull);
    expect(V.integer(min: 1990, max: 2100)('1980'), isNotNull);
    expect(V.integer(min: 1990, max: 2100)('2024'), isNull);
  });

  test('email and phone have their own formats', () {
    expect(V.email()('anna.sokolova@nyamka.test'), isNull);
    expect(V.email()('не почта'), isNotNull);
    expect(V.phone()('+74951110001'), isNull);
    expect(V.phone()('123'), isNotNull);
  });

  test('registration password needs length, a digit and a symbol', () {
    expect(passwordIssue(''), isNotNull);
    expect(passwordIssue('коротко'), isNotNull);
    expect(passwordIssue('nyamkany'), isNotNull);
    expect(passwordIssue('nyamka12'), isNotNull);
    expect(passwordIssue('Nyamka1!'), isNull);
  });

  test('product json without fields does not throw', () {
    final product = Product.fromJson({'id': 1});
    expect(product.name, '');
    expect(product.sku, '');
    expect(product.confectionerIds, isEmpty);
    expect(product.flavorTagIds, isEmpty);
  });
}
