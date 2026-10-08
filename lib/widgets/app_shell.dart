import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../core/breakpoints.dart';

class _Dest {
  const _Dest(this.path, this.label, this.icon, this.action);

  final String path;
  final String label;
  final IconData icon;
  final AppAction? action;
}

const _catalog = [
  _Dest('/', 'Главная', Icons.home_outlined, null),
  _Dest('/products', 'Каталог', Icons.cake_outlined, AppAction.viewCatalog),
  _Dest(
    '/categories',
    'Категории',
    Icons.category_outlined,
    AppAction.manageCatalog,
  ),
  _Dest(
    '/confectioners',
    'Кондитеры',
    Icons.badge_outlined,
    AppAction.viewCatalog,
  ),
  _Dest('/flavors', 'Вкусы', Icons.icecream_outlined, AppAction.viewCatalog),
  _Dest('/workshops', 'Цеха', Icons.storefront_outlined, AppAction.viewCatalog),
  _Dest(
    '/customers',
    'Покупатели',
    Icons.people_outline,
    AppAction.manageCustomers,
  ),
  _Dest(
    '/my-orders',
    'Мои заказы',
    Icons.receipt_long_outlined,
    AppAction.viewOwnOrders,
  ),
  _Dest(
    '/orders',
    'Заказы',
    Icons.point_of_sale_outlined,
    AppAction.manageOrders,
  ),
  _Dest(
    '/admin/users',
    'Пользователи',
    Icons.manage_accounts_outlined,
    AppAction.manageUsers,
  ),
  _Dest(
    '/admin/stats',
    'Статистика',
    Icons.insights_outlined,
    AppAction.viewStats,
  ),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final dests = [
      for (final item in _catalog)
        if (item.action == null || auth.allows(item.action!)) item,
    ];
    final location = GoRouterState.of(context).uri.path;
    final selected = _selectedIndex(location, dests);
    final size = screenSizeOf(context);
    final compact = size == ScreenSize.compact;

    return Scaffold(
      body: Row(
        children: [
          if (!compact)
            _Rail(
              dests: dests,
              selected: selected,
              extended: size != ScreenSize.medium,
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = size == ScreenSize.wide
                    ? 1200.0
                    : constraints.maxWidth;
                final pageWidth = width > constraints.maxWidth
                    ? constraints.maxWidth
                    : width;
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: pageWidth,
                    height: constraints.maxHeight,
                    child: child,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: compact
          ? _BottomNav(dests: dests, selected: selected)
          : null,
    );
  }
}

int _selectedIndex(String location, List<_Dest> dests) {
  var best = 0;
  var bestLen = -1;
  for (var i = 0; i < dests.length; i++) {
    final path = dests[i].path;
    final hit = path == '/'
        ? location == '/'
        : location == path || location.startsWith('$path/');
    if (hit && path.length > bestLen) {
      best = i;
      bestLen = path.length;
    }
  }
  return best;
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.dests,
    required this.selected,
    required this.extended,
  });

  final List<_Dest> dests;
  final int selected;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final needed = dests.length * 72.0 + 16;
        final height = needed > constraints.maxHeight
            ? needed
            : constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: NavigationRail(
              extended: extended,
              selectedIndex: selected,
              onDestinationSelected: (index) => context.go(dests[index].path),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              destinations: [
                for (final item in dests)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.dests, required this.selected});

  final List<_Dest> dests;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final overflow = dests.length > 5;
    final shown = overflow ? dests.sublist(0, 4) : dests;
    final extra = overflow ? dests.sublist(4) : const <_Dest>[];
    final inExtra = overflow && selected >= shown.length;
    final index = inExtra ? shown.length : selected;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) {
        if (overflow && value == shown.length) {
          _openMore(context, extra);
          return;
        }
        context.go(shown[value].path);
      },
      destinations: [
        for (final item in shown)
          NavigationDestination(icon: Icon(item.icon), label: item.label),
        if (overflow)
          const NavigationDestination(icon: Icon(Icons.menu), label: 'Ещё'),
      ],
    );
  }

  void _openMore(BuildContext context, List<_Dest> extra) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in extra)
              ListTile(
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(item.path);
                },
              ),
          ],
        ),
      ),
    );
  }
}
