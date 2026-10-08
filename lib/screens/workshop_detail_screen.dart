import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/workshop_repository.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';
import '../widgets/api_feedback.dart';
import '../widgets/workshop_delete_guard.dart';

class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key, required this.workshopId});

  final int workshopId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Цех #$workshopId')),
      body: FutureBuilder<Workshop?>(
        future: context.read<WorkshopRepository>().findById(workshopId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snapshot.data;
          if (item == null) {
            return Center(child: FilledButton(onPressed: () => context.go('/workshops'), child: const Text('К списку')));
          }
          final flavors = context.read<FlavorRepository>().all;
          final flavorNames = item.flavorIds
              .map((id) {
                for (final flavor in flavors) {
                  if (flavor.id == id) return flavor.name;
                }
                return '?';
              })
              .join(', ');
          final linked = context.read<ProductRepository>().countByWorkshop(item.id);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Город: ${item.city}'),
                  Text('Телефон: ${item.phone}'),
                  Text('Вкусы: $flavorNames'),
                  Text('Связанных изделий: $linked'),
                  if (item.isDeleted) Text('Удалён: ${item.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                        FilledButton(onPressed: () => context.push('/workshops/${item.id}/edit'), child: const Text('Изменить')),
                      FilledButton(onPressed: () => context.go('/workshops'), child: const Text('К списку')),
                      if (item.isDeleted && context.watch<AuthNotifier>().allows(AppAction.restore))
                        FilledButton.tonal(onPressed: () => _restore(context, item.id), child: const Text('Восстановить'))
                      else if (!item.isDeleted) ...[
                        if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                          FilledButton.tonal(onPressed: () => _remove(context, item.id, soft: true), child: const Text('Скрыть')),
                        if (context.watch<AuthNotifier>().allows(AppAction.hardDelete))
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                            onPressed: () => _remove(context, item.id, soft: false),
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

  Future<void> _remove(BuildContext context, int id, {required bool soft}) async {
    final notifier = context.read<CatalogNotifier<Workshop, WorkshopQuery>>();
    final done = await runWorkshopDelete(context, () async {
      if (soft) {
        await notifier.softDeleteOne(id);
      } else {
        await notifier.hardDeleteOne(id);
      }
    });
    if (!done || !context.mounted) return;
    if (soft) {
      context.go(workshopQueryToLocation(notifier.query));
    } else {
      context.go('/workshops');
    }
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<CatalogNotifier<Workshop, WorkshopQuery>>();
    await showFailure(context, () async {
      await notifier.restoreOne(id);
      if (context.mounted) context.go(workshopQueryToLocation(notifier.query));
    });
  }
}
