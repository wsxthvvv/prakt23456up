import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/confectioner_detail_screen.dart';
import '../screens/confectioner_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_list_screen.dart';
import 'confectioner_query_sync.dart';
import 'product_query_sync.dart';

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
        GoRoute(
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return NotFoundScreen(location: state.uri.toString());
            }
            return ProductDetailScreen(productId: id);
          },
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
          path: ':id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            if (id == null) {
              return NotFoundScreen(location: state.uri.toString());
            }
            return ConfectionerDetailScreen(confectionerId: id);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.toString()),
);
