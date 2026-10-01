import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../models/customer_query.dart';
import '../repositories/customer_repository.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Покупатель #$customerId')),
      body: FutureBuilder<Customer?>(
        future: context.read<CustomerRepository>().findById(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return Center(child: FilledButton(onPressed: () => context.go('/customers'), child: const Text('К списку')));
          }
          final card = item.loyaltyCard;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(item.fullName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Почта: ${item.email}'),
                  Text('Телефон: ${item.phone}'),
                  const SizedBox(height: 12),
                  Text('Карта: ${card.number}'),
                  Text('Выдана: ${card.issuedOn}'),
                  Text('Скидка: ${card.discountPercent}%'),
                  Text('Статус карты: ${card.active ? 'активна' : 'неактивна'}'),
                  if (item.isDeleted) Text('Удалён: ${item.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(onPressed: () => context.push('/customers/${item.id}/edit'), child: const Text('Изменить')),
                      FilledButton(onPressed: () => context.go('/customers'), child: const Text('К списку')),
                      if (item.isDeleted)
                        FilledButton.tonal(onPressed: () => _restore(context, item.id), child: const Text('Восстановить'))
                      else ...[
                        FilledButton.tonal(onPressed: () => _soft(context, item.id), child: const Text('Скрыть')),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                          onPressed: () => _hard(context, item.id),
                          child: const Text('Удалить навсегда'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _soft(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Customer, CustomerQuery>>();
    await notifier.softDeleteOne(id);
    if (context.mounted) context.go(customerQueryToLocation(notifier.query));
  }

  Future<void> _hard(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Customer, CustomerQuery>>();
    await notifier.hardDeleteOne(id);
    if (context.mounted) context.go('/customers');
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Customer, CustomerQuery>>();
    await notifier.restoreOne(id);
    if (context.mounted) context.go(customerQueryToLocation(notifier.query));
  }
}
