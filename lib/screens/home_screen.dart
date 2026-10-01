import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../storage/app_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AppStorage>().notice;
    return Scaffold(
      appBar: AppBar(title: const Text('Кондитерская «нямка»')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Text(
                'Клиентская система витрины кондитерской. Каталог изделий, кондитеры, вкусы, цеха и покупатели с картами лояльности.',
                textAlign: TextAlign.center,
              ),
              if (notice != null) ...[
                const SizedBox(height: 16),
                MaterialBanner(
                  content: Text(notice),
                  actions: [
                    TextButton(
                      onPressed: () => context.read<AppStorage>().dismiss(),
                      child: const Text('Скрыть'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _link(context, '/products', 'Каталог изделий'),
              _link(context, '/confectioners', 'Кондитеры'),
              _link(context, '/flavors', 'Вкусы'),
              _link(context, '/workshops', 'Цеха'),
              _link(context, '/customers', 'Покупатели'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(BuildContext context, String path, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(onPressed: () => context.go(path), child: Text(label)),
      ),
    );
  }
}
