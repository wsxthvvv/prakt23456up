import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../screens/confectioner_detail_screen.dart';
import '../screens/confectioner_form_screen.dart';
import '../screens/confectioner_list_screen.dart';
import '../screens/customer_detail_screen.dart';
import '../screens/customer_form_screen.dart';
import '../screens/customer_list_screen.dart';
import '../screens/flavor_detail_screen.dart';
import '../screens/flavor_form_screen.dart';
import '../screens/flavor_list_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_orders_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/order_desk_screen.dart';
import '../screens/register_screen.dart';
import '../screens/stats_screen.dart' deferred as stats_screen;
import '../screens/users_screen.dart' deferred as users_screen;
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/workshop_detail_screen.dart';
import '../screens/workshop_form_screen.dart';
import '../screens/workshop_list_screen.dart';
import '../state/catalog_notifier.dart';
import '../widgets/app_shell.dart';
import '../widgets/deferred_page.dart';
import 'confectioner_query_sync.dart';
import 'product_query_sync.dart';
import 'query_codec.dart';
import 'query_equality.dart';
import 'query_sync.dart';

GoRouter buildRouter(
  AuthNotifier auth, {
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.matchedLocation;
      final isPublic = target == '/login' || target == '/register';
      if (!loggedIn && !isPublic) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (loggedIn && isPublic) {
        final from = state.uri.queryParameters['from'];
        if (from != null &&
            from.startsWith('/') &&
            !from.startsWith('/login') &&
            !from.startsWith('/register')) {
          return from;
        }
        return '/';
      }
      if (!loggedIn) return null;
      final role = auth.role;
      if (role == null) return '/login';
      if (target == '/my-orders') {
        return allowsAction(role, AppAction.viewOwnOrders)
            ? null
            : '/forbidden';
      }
      if (target == '/orders') {
        return allowsAction(role, AppAction.manageOrders) ? null : '/forbidden';
      }
      if (target.startsWith('/admin')) {
        return allowsAction(role, AppAction.manageUsers) ? null : '/forbidden';
      }
      if (target.startsWith('/customers')) {
        return allowsAction(role, AppAction.manageCustomers)
            ? null
            : '/forbidden';
      }
      final staffWrite = RegExp(
        r'^/(products|confectioners|flavors|workshops)/(new|.+/edit)$',
      ).hasMatch(target);
      if (staffWrite) {
        return allowsAction(role, AppAction.manageCatalog)
            ? null
            : '/forbidden';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => const ForbiddenScreen(),
          ),
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/my-orders',
            builder: (context, state) => const MyOrdersScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrderDeskScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => DeferredPage(
              load: users_screen.loadLibrary,
              builder: () => users_screen.UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/stats',
            builder: (context, state) => DeferredPage(
              load: stats_screen.loadLibrary,
              builder: () => stats_screen.StatsScreen(),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => ProductQuerySync(
              key: ValueKey(state.uri.toString()),
              child: const ProductListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ProductFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => _detailOrMissing(
                  state,
                  (id) => ProductDetailScreen(productId: id),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => _detailOrMissing(
                      state,
                      (id) => ProductFormScreen(id: id),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/confectioners',
            builder: (context, state) => ConfectionerQuerySync(
              key: ValueKey(state.uri.toString()),
              child: const ConfectionerListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const ConfectionerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => _detailOrMissing(
                  state,
                  (id) => ConfectionerDetailScreen(confectionerId: id),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => _detailOrMissing(
                      state,
                      (id) => ConfectionerFormScreen(id: id),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/flavors',
            builder: (context, state) => QuerySync<FlavorQuery>(
              key: ValueKey(state.uri.toString()),
              parse: flavorQueryFromUri,
              current: (context) =>
                  context.read<CatalogNotifier<Flavor, FlavorQuery>>().query,
              equals: flavorQueriesEqual,
              apply: (context, query) => context
                  .read<CatalogNotifier<Flavor, FlavorQuery>>()
                  .applyQuery(query),
              child: const FlavorListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const FlavorFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => _detailOrMissing(
                  state,
                  (id) => FlavorDetailScreen(flavorId: id),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => _detailOrMissing(
                      state,
                      (id) => FlavorFormScreen(id: id),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/workshops',
            builder: (context, state) => QuerySync<WorkshopQuery>(
              key: ValueKey(state.uri.toString()),
              parse: workshopQueryFromUri,
              current: (context) => context
                  .read<CatalogNotifier<Workshop, WorkshopQuery>>()
                  .query,
              equals: workshopQueriesEqual,
              apply: (context, query) => context
                  .read<CatalogNotifier<Workshop, WorkshopQuery>>()
                  .applyQuery(query),
              child: const WorkshopListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const WorkshopFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => _detailOrMissing(
                  state,
                  (id) => WorkshopDetailScreen(workshopId: id),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => _detailOrMissing(
                      state,
                      (id) => WorkshopFormScreen(id: id),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => QuerySync<CustomerQuery>(
              key: ValueKey(state.uri.toString()),
              parse: customerQueryFromUri,
              current: (context) => context
                  .read<CatalogNotifier<Customer, CustomerQuery>>()
                  .query,
              equals: customerQueriesEqual,
              apply: (context, query) => context
                  .read<CatalogNotifier<Customer, CustomerQuery>>()
                  .applyQuery(query),
              child: const CustomerListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => _detailOrMissing(
                  state,
                  (id) => CustomerDetailScreen(customerId: id),
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => _detailOrMissing(
                      state,
                      (id) => CustomerFormScreen(id: id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}

Widget _detailOrMissing(GoRouterState state, Widget Function(int id) build) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) return NotFoundScreen(location: state.uri.toString());
  return build(id);
}
