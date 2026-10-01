import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/load_status.dart';
import 'list_status_body.dart';

Future<bool> confirmLogicalDelete(BuildContext context, int count) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Удалить выбранные?'),
      content: Text('Будет выполнено логическое удаление ($count шт.)'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
      ],
    ),
  );
  return ok == true;
}

class CatalogFrame extends StatelessWidget {
  const CatalogFrame({
    super.key,
    required this.title,
    required this.onCreate,
    required this.selectedCount,
    required this.onDeleteSelected,
    required this.filtersExpanded,
    required this.onToggleFilters,
    required this.filters,
    required this.status,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    required this.body,
    required this.pagination,
  });

  final String title;
  final VoidCallback onCreate;
  final int selectedCount;
  final VoidCallback? onDeleteSelected;
  final bool filtersExpanded;
  final VoidCallback onToggleFilters;
  final List<Widget> filters;
  final LoadStatus status;
  final String? error;
  final bool isEmpty;
  final VoidCallback onRetry;
  final Widget body;
  final Widget pagination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (selectedCount > 0)
            TextButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete_outline),
              label: Text('Удалить ($selectedCount)'),
            ),
          IconButton(tooltip: 'Добавить', onPressed: onCreate, icon: const Icon(Icons.add)),
          IconButton(tooltip: 'На главную', onPressed: () => context.go('/'), icon: const Icon(Icons.home)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleFilters,
                icon: Icon(filtersExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(filtersExpanded ? 'Скрыть фильтры' : 'Показать фильтры'),
              ),
            ),
            if (filtersExpanded)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: filters,
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListStatusBody(
                status: status,
                error: error,
                isEmpty: isEmpty,
                onRetry: onRetry,
                child: Column(
                  children: [
                    Expanded(child: body),
                    const SizedBox(height: 8),
                    pagination,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
