import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../models/confectioner.dart';
import '../widgets/api_feedback.dart';
import '../repositories/confectioner_repository.dart';
import '../repositories/workshop_repository.dart';
import '../routing/query_codec.dart';
import '../state/confectioner_list_notifier.dart';

class ConfectionerDetailScreen extends StatelessWidget {
  const ConfectionerDetailScreen({super.key, required this.confectionerId});

  final int confectionerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Кондитер #$confectionerId'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: FutureBuilder<Confectioner?>(
        future: context.read<ConfectionerRepository>().findById(confectionerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final c = snapshot.data;
          if (c == null) {
            return Center(
              child: FilledButton(onPressed: () => context.go('/confectioners'), child: const Text('К списку')),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(c.fullName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text('Страна: ${c.country}'),
                  Text('Специализация: ${c.specialty}'),
                  Text('Цех: ${_workshopName(context, c.workshopId)}'),
                  if (c.isDeleted) Text('Удалён: ${c.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                        FilledButton(
                          onPressed: () => context.push('/confectioners/${c.id}/edit'),
                          child: const Text('Изменить'),
                        ),
                      FilledButton(onPressed: () => context.go('/confectioners'), child: const Text('К списку')),
                      if (c.isDeleted && context.watch<AuthNotifier>().allows(AppAction.restore))
                        FilledButton.tonal(
                          onPressed: () => _restore(context, c.id),
                          child: const Text('Восстановить'),
                        )
                      else if (!c.isDeleted) ...[
                        if (context.watch<AuthNotifier>().allows(AppAction.manageCatalog))
                          FilledButton.tonal(
                            onPressed: () => _softDelete(context, c.id),
                            child: const Text('Скрыть'),
                          ),
                        if (context.watch<AuthNotifier>().allows(AppAction.hardDelete))
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _hardDelete(context, c.id),
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

  String _workshopName(BuildContext context, int id) {
    for (final workshop in context.read<WorkshopRepository>().all) {
      if (workshop.id == id) return workshop.name;
    }
    return '—';
  }

  Future<void> _softDelete(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await showFailure(context, () async {
      await notifier.softDeleteOne(id);
      if (context.mounted) context.go(confectionerQueryToLocation(notifier.query));
    });
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await showFailure(context, () async {
      await notifier.hardDeleteOne(id);
      if (context.mounted) context.go('/confectioners');
    });
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await showFailure(context, () async {
      await notifier.restoreOne(id);
      if (context.mounted) context.go(confectionerQueryToLocation(notifier.query));
    });
  }
}
