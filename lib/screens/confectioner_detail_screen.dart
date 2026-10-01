import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/confectioner.dart';
import '../repositories/confectioner_repository.dart';
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
                  if (c.isDeleted) Text('Удалён: ${c.deletedAt}'),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(onPressed: () => context.go('/confectioners'), child: const Text('К списку')),
                      if (c.isDeleted)
                        FilledButton.tonal(
                          onPressed: () => _restore(context, c.id),
                          child: const Text('Восстановить'),
                        )
                      else ...[
                        FilledButton.tonal(
                          onPressed: () => _softDelete(context, c.id),
                          child: const Text('Скрыть'),
                        ),
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

  Future<void> _softDelete(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await notifier.softDeleteOne(id);
    if (context.mounted) context.go(confectionerQueryToLocation(notifier.query));
  }

  Future<void> _hardDelete(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await notifier.hardDeleteOne(id);
    if (context.mounted) context.go('/confectioners');
  }

  Future<void> _restore(BuildContext context, int id) async {
    final notifier = context.read<ConfectionerListNotifier>();
    await notifier.restoreOne(id);
    if (context.mounted) context.go(confectionerQueryToLocation(notifier.query));
  }
}
