import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/workshop_detail_screen.dart';
import '../screens/workshop_form_screen.dart';
import '../screens/workshop_list_screen.dart';
import '../state/catalog_notifier.dart';
import 'confectioner_query_sync.dart';
import 'product_query_sync.dart';
import 'query_codec.dart';
import 'query_equality.dart';
import 'query_sync.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/products',
      builder: (context, state) => ProductQuerySync(
        key: ValueKey(state.uri.toString()),
        child: const ProductListScreen(),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const ProductFormScreen()),
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
        GoRoute(path: 'new', builder: (context, state) => const ConfectionerFormScreen()),
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
        current: (context) => context.read<CatalogNotifier<Flavor, FlavorQuery>>().query,
        equals: flavorQueriesEqual,
        apply: (context, query) => context.read<CatalogNotifier<Flavor, FlavorQuery>>().applyQuery(query),
        child: const FlavorListScreen(),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const FlavorFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => _detailOrMissing(state, (id) => FlavorDetailScreen(flavorId: id)),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => _detailOrMissing(state, (id) => FlavorFormScreen(id: id)),
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
        current: (context) => context.read<CatalogNotifier<Workshop, WorkshopQuery>>().query,
        equals: workshopQueriesEqual,
        apply: (context, query) => context.read<CatalogNotifier<Workshop, WorkshopQuery>>().applyQuery(query),
        child: const WorkshopListScreen(),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const WorkshopFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => _detailOrMissing(state, (id) => WorkshopDetailScreen(workshopId: id)),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => _detailOrMissing(state, (id) => WorkshopFormScreen(id: id)),
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
        current: (context) => context.read<CatalogNotifier<Customer, CustomerQuery>>().query,
        equals: customerQueriesEqual,
        apply: (context, query) => context.read<CatalogNotifier<Customer, CustomerQuery>>().applyQuery(query),
        child: const CustomerListScreen(),
      ),
      routes: [
        GoRoute(path: 'new', builder: (context, state) => const CustomerFormScreen()),
        GoRoute(
          path: ':id',
          builder: (context, state) => _detailOrMissing(state, (id) => CustomerDetailScreen(customerId: id)),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => _detailOrMissing(state, (id) => CustomerFormScreen(id: id)),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);

Widget _detailOrMissing(GoRouterState state, Widget Function(int id) build) {
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null) return NotFoundScreen(location: state.uri.toString());
  return build(id);
}
