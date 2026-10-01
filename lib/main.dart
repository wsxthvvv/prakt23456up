import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'routing/router.dart';
import 'repositories/confectioner_repository.dart';
import 'repositories/in_memory_confectioner_repository.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/product_repository.dart';
import 'state/confectioner_list_notifier.dart';
import 'state/product_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        Provider<ProductRepository>(create: (_) => InMemoryProductRepository()),
        Provider<ConfectionerRepository>(create: (_) => InMemoryConfectionerRepository()),
        ChangeNotifierProvider(
          create: (context) => ProductListNotifier(context.read<ProductRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => ConfectionerListNotifier(context.read<ConfectionerRepository>())..load(),
        ),
      ],
      child: const NyamkaApp(),
    ),
  );
}

class NyamkaApp extends StatelessWidget {
  const NyamkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Кондитерская «нямка»',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
