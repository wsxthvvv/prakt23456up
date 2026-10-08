import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../storage/app_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<AppStorage>().notice;
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кондитерская «нямка»'),
        actions: [
          if (user != null) ...[
            Center(child: Text(user.fullName)),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Выйти',
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
            ),
          ],
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Text(
                user == null
                    ? 'Клиентская система витрины кондитерской.'
                    : '${user.fullName}, роль: ${roleTitle(user.role)}',
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
              if (auth.allows(AppAction.viewCatalog)) ...[
                _link(context, '/products', 'Каталог изделий'),
                _link(context, '/confectioners', 'Кондитеры'),
                _link(context, '/flavors', 'Вкусы'),
                _link(context, '/workshops', 'Цеха'),
              ],
              if (auth.allows(AppAction.manageCustomers))
                _link(context, '/customers', 'Покупатели'),
              if (auth.allows(AppAction.viewOwnOrders))
                _link(context, '/my-orders', 'Мои заказы'),
              if (auth.allows(AppAction.manageOrders))
                _link(context, '/orders', 'Оформление заказов'),
              if (auth.allows(AppAction.manageUsers))
                _link(context, '/admin/users', 'Пользователи'),
              if (auth.allows(AppAction.viewStats))
                _link(context, '/admin/stats', 'Статистика'),
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
        child: FilledButton(
          onPressed: () => context.go(path),
          child: Text(label),
        ),
      ),
    );
  }
}
