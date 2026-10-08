import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../models/flavor.dart';
import '../widgets/api_feedback.dart';
import '../models/flavor_query.dart';
import '../repositories/flavor_repository.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';

class FlavorDetailScreen extends StatelessWidget {
  const FlavorDetailScreen({super.key, required this.flavorId});

  final int flavorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Вкус #$flavorId')),
      body: FutureBuilder<Flavor?>(
        future: context.read<FlavorRepository>().findById(flavorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return Center(child: FilledButton(onPressed: () => context.go('/flavors'), child: const Text('К списку')));
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Описание: ${item.description}'),
                  Text('Интенсивность: ${item.intensity}'),
                  if (item.isDeleted) Text('Удалён: ${item.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                        FilledButton(onPressed: () => context.push('/flavors/${item.id}/edit'), child: const Text('Изменить')),
                      FilledButton(onPressed: () => context.go('/flavors'), child: const Text('К списку')),
                      if (item.isDeleted && context.watch<AuthNotifier>().allows(AppAction.restore))
                        FilledButton.tonal(onPressed: () => _restore(context, item.id), child: const Text('Восстановить'))
                      else if (!item.isDeleted) ...[
                        if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                          FilledButton.tonal(onPressed: () => _soft(context, item.id), child: const Text('Скрыть')),
                        if (context.watch<AuthNotifier>().allows(AppAction.hardDelete))
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
    final notifier = context.read<CatalogNotifier<Flavor, FlavorQuery>>();
    await showFailure(context, () async {
      await notifier.softDeleteOne(id);
      if (context.mounted) context.go(flavorQueryToLocation(notifier.query));
    });
  }

  Future<void> _hard(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Flavor, FlavorQuery>>();
    await showFailure(context, () async {
      await notifier.hardDeleteOne(id);
      if (context.mounted) context.go('/flavors');
    });
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Flavor, FlavorQuery>>();
    await showFailure(context, () async {
      await notifier.restoreOne(id);
      if (context.mounted) context.go(flavorQueryToLocation(notifier.query));
    });
  }
}
