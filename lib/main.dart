import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth/auth_notifier.dart';
import 'auth/inactivity_watcher.dart';
import 'core/api_client.dart';
import 'core/app_theme.dart';
import 'models/customer.dart';
import 'models/customer_query.dart';
import 'models/flavor.dart';
import 'models/flavor_query.dart';
import 'models/workshop.dart';
import 'models/workshop_query.dart';
import 'repositories/api_confectioner_repository.dart';
import 'repositories/api_customer_repository.dart';
import 'repositories/api_flavor_repository.dart';
import 'repositories/api_product_repository.dart';
import 'repositories/api_reference_repository.dart';
import 'repositories/api_workshop_repository.dart';
import 'repositories/confectioner_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/flavor_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/reference_repository.dart';
import 'repositories/workshop_repository.dart';
import 'routing/router.dart';
import 'state/catalog_notifier.dart';
import 'state/confectioner_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'storage/app_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final storage = await AppStorage.open();
  final auth = AuthNotifier(storage.prefs);
  final navigatorKey = GlobalKey<NavigatorState>();
  final dio = buildDio(
    tokenProvider: () => auth.accessToken,
    refresh: auth.refreshTokens,
    onSessionLost: () => auth.logout(reason: SessionEnd.refresh, remote: false),
  );
  auth.bind(dio);
  try {
    await auth.restore().timeout(const Duration(seconds: 4));
  } catch (_) {}
  final products = ApiProductRepository(dio);
  final confectioners = ApiConfectionerRepository(dio);
  final flavors = ApiFlavorRepository(dio);
  final workshops = ApiWorkshopRepository(dio);
  final customers = ApiCustomerRepository(dio);
  final references = ApiReferenceRepository(dio);
  try {
    await Future.wait([
      products.warm(),
      confectioners.warm(),
      flavors.warm(),
      workshops.warm(),
      customers.warm(),
      references.warm(),
    ]).timeout(const Duration(seconds: 8));
  } catch (_) {}
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStorage>.value(value: storage),
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        Provider<Dio>.value(value: dio),
        Provider<ProductRepository>.value(value: products),
        Provider<ConfectionerRepository>.value(value: confectioners),
        Provider<FlavorRepository>.value(value: flavors),
        Provider<WorkshopRepository>.value(value: workshops),
        Provider<CustomerRepository>.value(value: customers),
        Provider<ReferenceRepository>.value(value: references),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListNotifier(context.read<ProductRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ConfectionerListNotifier(context.read<ConfectionerRepository>())
                ..load(),
        ),
        ChangeNotifierProvider<CatalogNotifier<Flavor, FlavorQuery>>(
          create: (context) {
            final repo = context.read<FlavorRepository>();
            return CatalogNotifier<Flavor, FlavorQuery>(
              find: repo.find,
              softDelete: repo.softDelete,
              hardDelete: repo.hardDelete,
              restore: repo.restore,
              deleteMany: repo.deleteMany,
              initialQuery: const FlavorQuery(),
            )..load();
          },
        ),
        ChangeNotifierProvider<CatalogNotifier<Workshop, WorkshopQuery>>(
          create: (context) {
            final repo = context.read<WorkshopRepository>();
            return CatalogNotifier<Workshop, WorkshopQuery>(
              find: repo.find,
              softDelete: repo.softDelete,
              hardDelete: repo.hardDelete,
              restore: repo.restore,
              deleteMany: repo.deleteMany,
              initialQuery: const WorkshopQuery(),
            )..load();
          },
        ),
        ChangeNotifierProvider<CatalogNotifier<Customer, CustomerQuery>>(
          create: (context) {
            final repo = context.read<CustomerRepository>();
            return CatalogNotifier<Customer, CustomerQuery>(
              find: repo.find,
              softDelete: repo.softDelete,
              hardDelete: repo.hardDelete,
              restore: repo.restore,
              deleteMany: repo.deleteMany,
              initialQuery: const CustomerQuery(),
            )..load();
          },
        ),
      ],
      child: NyamkaApp(
        router: buildRouter(auth, navigatorKey: navigatorKey),
        navigatorKey: navigatorKey,
      ),
    ),
  );
}

class NyamkaApp extends StatelessWidget {
  const NyamkaApp({
    super.key,
    required this.router,
    required this.navigatorKey,
  });

  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return MaterialApp.router(
      title: 'Кондитерская «нямка»',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return InactivityWatcher(
          enabled: auth.isAuthenticated,
          timeout: inactivityLimit,
          initialTimeout: auth.inactivityLeft,
          warning: inactivityWarning,
          navigatorKey: navigatorKey,
          onActivity: auth.markActivity,
          onTimeout: () => auth.logout(reason: SessionEnd.inactive),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
