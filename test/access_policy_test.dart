import 'package:flutter_test/flutter_test.dart';
import 'package:prakt2up/auth/access_policy.dart';

void main() {
  test('buyer can open own orders and cannot manage the catalog', () {
    expect(allowsAction(AppRole.buyer, AppAction.viewOwnOrders), isTrue);
    expect(allowsAction(AppRole.buyer, AppAction.manageCatalog), isFalse);
    expect(allowsAction(AppRole.buyer, AppAction.manageOrders), isFalse);
  });

  test('seller runs the order desk and catalog, not user administration', () {
    expect(allowsAction(AppRole.seller, AppAction.manageOrders), isTrue);
    expect(allowsAction(AppRole.seller, AppAction.manageCatalog), isTrue);
    expect(allowsAction(AppRole.seller, AppAction.manageCustomers), isTrue);
    expect(allowsAction(AppRole.seller, AppAction.manageUsers), isFalse);
    expect(allowsAction(AppRole.seller, AppAction.viewOwnOrders), isFalse);
  });

  test('admin manages users, statistics and permanent deletion', () {
    expect(allowsAction(AppRole.admin, AppAction.manageUsers), isTrue);
    expect(allowsAction(AppRole.admin, AppAction.viewStats), isTrue);
    expect(allowsAction(AppRole.admin, AppAction.hardDelete), isTrue);
    expect(allowsAction(AppRole.admin, AppAction.restore), isTrue);
  });

  test('admin cannot open the buyer or seller exclusive screens', () {
    expect(allowsAction(AppRole.admin, AppAction.viewOwnOrders), isFalse);
    expect(allowsAction(AppRole.admin, AppAction.manageOrders), isFalse);
  });

  test('every role can view the catalog', () {
    for (final role in AppRole.values) {
      expect(allowsAction(role, AppAction.viewCatalog), isTrue);
    }
  });

  test('only an administrator restores a deleted record', () {
    expect(allowsAction(AppRole.buyer, AppAction.restore), isFalse);
    expect(allowsAction(AppRole.seller, AppAction.restore), isFalse);
    expect(allowsAction(AppRole.admin, AppAction.restore), isTrue);
  });
}
