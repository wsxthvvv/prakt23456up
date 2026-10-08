import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../core/breakpoints.dart';
import '../widgets/api_feedback.dart';
import '../routing/query_codec.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/reference_repository.dart';
import '../repositories/workshop_repository.dart';
import '../state/product_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_status_body.dart';
import '../widgets/pagination_bar.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _filtersExpanded = true;

  void _navigate(ProductQuery query) {
    context.go(productQueryToLocation(query));
  }

  Future<void> _confirmDeleteSelected(ProductListNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранные?'),
        content: Text('Будет выполнено логическое удаление (${notifier.selected.length} шт.)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await notifier.deleteSelected();
      _navigate(notifier.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductListNotifier>();
    final q = notifier.query;
    final compact = isCompactWidth(context);
    final manage = context.watch<AuthNotifier>().allows(AppAction.manageCatalog);
    final restore = context.watch<AuthNotifier>().allows(AppAction.restore);
    final hard = context.watch<AuthNotifier>().allows(AppAction.hardDelete);
    final references = context.watch<ReferenceRepository>();
    final flavors = context
        .read<FlavorRepository>()
        .all
        .where((flavor) => !flavor.isDeleted || flavor.id == q.flavorTagId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог изделий'),
        actions: [
          if (manage && notifier.hasSelection)
            TextButton.icon(
              onPressed: () => _confirmDeleteSelected(notifier),
              icon: const Icon(Icons.delete_outline),
              label: Text('Удалить (${notifier.selected.length})'),
            ),
          if (manage)
            IconButton(
              tooltip: 'Новое изделие',
              onPressed: () => context.push('/products/new'),
              icon: const Icon(Icons.add),
            ),
          IconButton(
            tooltip: 'На главную',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.home),
          ),
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
                onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
                icon: Icon(_filtersExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(_filtersExpanded ? 'Скрыть фильтры' : 'Показать фильтры'),
              ),
            ),
            if (_filtersExpanded)
              Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: DebouncedSearchField(
                    initialValue: q.search,
                    label: 'Поиск по названию или артикулу',
                    onChanged: (value) => _navigate(q.copyWith(search: value)),
                  ),
                ),
                FilterDropdown<int?>(
                  label: 'Категория',
                  width: 240,
                  value: q.categoryId,
                  items: [
                    DropdownMenuItem(value: null, child: FilterDropdown.menuText('Все категории')),
                    for (final c in references.categories)
                      DropdownMenuItem(value: c.id, child: FilterDropdown.menuText(c.name)),
                  ],
                  onChanged: (value) => _navigate(q.copyWith(categoryId: value)),
                ),
                FilterDropdown<int?>(
                  label: 'Вкус',
                  value: q.flavorTagId,
                  items: [
                    DropdownMenuItem(value: null, child: FilterDropdown.menuText('Любой вкус')),
                    for (final flavor in flavors)
                      DropdownMenuItem(value: flavor.id, child: FilterDropdown.menuText(flavor.name)),
                  ],
                  onChanged: (value) => _navigate(q.copyWith(flavorTagId: value)),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    key: ValueKey('from-${q.yearFrom}'),
                    initialValue: q.yearFrom?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Год от', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (value) {
                      final year = int.tryParse(value.trim());
                      _navigate(q.copyWith(yearFrom: year));
                    },
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    key: ValueKey('to-${q.yearTo}'),
                    initialValue: q.yearTo?.toString() ?? '',
                    decoration: const InputDecoration(labelText: 'Год до', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onFieldSubmitted: (value) {
                      final year = int.tryParse(value.trim());
                      _navigate(q.copyWith(yearTo: year));
                    },
                  ),
                ),
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: q.includeDeleted,
                  onSelected: (value) => _navigate(q.copyWith(includeDeleted: value)),
                ),
              ],
            ),
            if (_filtersExpanded) const SizedBox(height: 8),
            const SizedBox(height: 16),
            Expanded(
              child: ListStatusBody(
                status: notifier.status,
                error: notifier.error,
                isEmpty: notifier.result.items.isEmpty,
                onRetry: () => context.read<ProductListNotifier>().load(),
                child: Column(
                  children: [
                    Expanded(
                      child: compact
                          ? _ProductCardList(
                              notifier: notifier,
                              onNavigate: _navigate,
                              manage: manage,
                              restore: restore,
                              hard: hard,
                            )
                          : _ProductTable(
                              notifier: notifier,
                              onNavigate: _navigate,
                              manage: manage,
                              restore: restore,
                              hard: hard,
                            ),
                    ),
                    const SizedBox(height: 8),
                    PaginationBar(
                      result: notifier.result,
                      onPageChanged: (page) => _navigate(q.copyWith(page: page)),
                      onSizeChanged: (size) => _navigate(q.copyWith(size: size)),
                    ),
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

class _ProductTable extends StatelessWidget {
  const _ProductTable({
    required this.notifier,
    required this.onNavigate,
    required this.manage,
    required this.restore,
    required this.hard,
  });

  final ProductListNotifier notifier;
  final void Function(ProductQuery query) onNavigate;
  final bool manage;
  final bool restore;
  final bool hard;

  @override
  Widget build(BuildContext context) {
    final q = notifier.query;
    final references = context.read<ReferenceRepository>();
    final workshopNames = {
      for (final workshop in context.read<WorkshopRepository>().all) workshop.id: workshop.name,
    };
    return EntityTable<Product>(
      items: notifier.result.items,
      idOf: (p) => p.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: q.sortField,
      sortAscending: q.sortAscending,
      onSort: (field) {
        onNavigate(
          q.copyWith(
            sortField: field,
            sortAscending: field == q.sortField ? !q.sortAscending : true,
          ),
        );
      },
      columns: [
        TableColumnSpec(label: 'Название', sortField: 'name', build: (p) => Text(p.name)),
        TableColumnSpec(label: 'Артикул', sortField: 'sku', build: (p) => Text(p.sku)),
        TableColumnSpec(label: 'Год', sortField: 'year', numeric: true, build: (p) => Text('${p.year}')),
        TableColumnSpec(label: 'Масса, г', sortField: 'weight', numeric: true, build: (p) => Text('${p.weightGrams}')),
        TableColumnSpec(label: 'Категория', build: (p) => Text(references.categoryName(p.categoryId))),
        TableColumnSpec(label: 'Цех', build: (p) => Text(workshopNames[p.workshopId] ?? '—')),
        TableColumnSpec(label: 'Остаток', numeric: true, build: (p) => Text('${p.stockAvailable}/${p.stockTotal}')),
      ],
      actions: (p) => _productActions(
        context,
        notifier,
        p,
        onNavigate,
        manage: manage,
        restore: restore,
        hard: hard,
      ),
    );
  }
}

class _ProductCardList extends StatelessWidget {
  const _ProductCardList({
    required this.notifier,
    required this.onNavigate,
    required this.manage,
    required this.restore,
    required this.hard,
  });

  final ProductListNotifier notifier;
  final void Function(ProductQuery query) onNavigate;
  final bool manage;
  final bool restore;
  final bool hard;

  @override
  Widget build(BuildContext context) {
    final references = context.read<ReferenceRepository>();
    final workshopNames = {
      for (final workshop in context.read<WorkshopRepository>().all) workshop.id: workshop.name,
    };
    return ListView.builder(
      itemCount: notifier.result.items.length,
      itemBuilder: (context, index) {
        final p = notifier.result.items[index];
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: notifier.selected.contains(p.id),
              onChanged: (_) => notifier.toggleSelection(p.id),
            ),
            title: Text(p.name),
            subtitle: Text('${p.sku} · ${references.categoryName(p.categoryId)} · ${workshopNames[p.workshopId] ?? '—'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: _productActions(
                context,
                notifier,
                p,
                onNavigate,
                manage: manage,
                restore: restore,
                hard: hard,
              ),
            ),
            onTap: () => context.push('/products/${p.id}'),
          ),
        );
      },
    );
  }
}

List<Widget> _productActions(
  BuildContext context,
  ProductListNotifier notifier,
  Product p,
  void Function(ProductQuery query) onNavigate, {
  required bool manage,
  required bool restore,
  required bool hard,
}) {
  return [
    IconButton(
      tooltip: 'Карточка',
      icon: const Icon(Icons.open_in_new),
      onPressed: () => context.push('/products/${p.id}'),
    ),
    if (manage)
      IconButton(
        tooltip: 'Изменить',
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => context.push('/products/${p.id}/edit'),
      ),
    if (p.isDeleted && restore)
      IconButton(
        tooltip: 'Восстановить',
        icon: const Icon(Icons.restore),
        onPressed: () => showFailure(context, () async {
          await notifier.restoreOne(p.id);
          onNavigate(notifier.query);
        }),
      )
    else if (!p.isDeleted) ...[
      if (manage)
        IconButton(
          tooltip: 'Скрыть (логическое удаление)',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => showFailure(context, () async {
            await notifier.softDeleteOne(p.id);
            onNavigate(notifier.query);
          }),
        ),
      if (hard)
        IconButton(
          tooltip: 'Удалить навсегда',
          icon: const Icon(Icons.delete_forever),
          onPressed: () => showFailure(context, () async {
            await notifier.hardDeleteOne(p.id);
            onNavigate(notifier.query);
          }),
        ),
    ],
  ];
}
