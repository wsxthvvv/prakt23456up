enum AppRole { buyer, seller, admin }

enum AppAction {
  viewCatalog,
  manageCatalog,
  manageCustomers,
  viewOwnOrders,
  manageOrders,
  hardDelete,
  restore,
  manageUsers,
  viewStats,
}

AppRole? roleByName(String? value) {
  return switch (value) {
    'buyer' => AppRole.buyer,
    'seller' => AppRole.seller,
    'admin' => AppRole.admin,
    _ => null,
  };
}

String roleTitle(AppRole role) {
  return switch (role) {
    AppRole.buyer => 'Покупатель',
    AppRole.seller => 'Продавец',
    AppRole.admin => 'Администратор',
  };
}

bool allowsAction(AppRole role, AppAction action) {
  return switch (action) {
    AppAction.viewCatalog => true,
    AppAction.manageCatalog || AppAction.manageCustomers =>
      role == AppRole.seller || role == AppRole.admin,
    AppAction.viewOwnOrders => role == AppRole.buyer,
    AppAction.manageOrders => role == AppRole.seller,
    AppAction.hardDelete ||
    AppAction.restore ||
    AppAction.manageUsers ||
    AppAction.viewStats => role == AppRole.admin,
  };
}

String? passwordIssue(String value) {
  if (value.isEmpty) return 'Укажите пароль';
  if (value.length < 8) return 'Не короче 8 символов';
  if (!RegExp(r'\d').hasMatch(value)) return 'Нужна хотя бы одна цифра';
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Нужен специальный символ';
  }
  return null;
}
