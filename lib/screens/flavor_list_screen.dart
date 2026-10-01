import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';
import '../widgets/catalog_frame.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/row_actions.dart';

class FlavorListScreen extends StatefulWidget {
  const FlavorListScreen({super.key});

  @override
  State<FlavorListScreen> createState() => _FlavorListScreenState();
}

class _FlavorListScreenState extends State<FlavorListScreen> {
  bool _filtersExpanded = true;

  CatalogNotifier<Flavor, FlavorQuery> get _notifier => context.read<CatalogNotifier<Flavor, FlavorQuery>>();

  void _navigate(FlavorQuery query) => context.go(flavorQueryToLocation(query));

  Future<void> _deleteSelected(CatalogNotifier<Flavor, FlavorQuery> notifier) async {
    final ok = await confirmLogicalDelete(context, notifier.selected.length);
    if (ok && mounted) {
      await notifier.deleteSelected();
      _navigate(notifier.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CatalogNotifier<Flavor, FlavorQuery>>();
    final q = notifier.query;
    final compact = isCompactWidth(context);
    return CatalogFrame(
      title: 'Вкусы',
      onCreate: () => context.push('/flavors/new'),
      selectedCount: notifier.selected.length,
      onDeleteSelected: () => _deleteSelected(notifier),
      filtersExpanded: _filtersExpanded,
      onToggleFilters: () => setState(() => _filtersExpanded = !_filtersExpanded),
      filters: [
        SizedBox(
          width: 260,
          child: DebouncedSearchField(
            initialValue: q.search,
            label: 'Поиск по названию или описанию',
            onChanged: (value) => _navigate(q.copyWith(search: value)),
          ),
        ),
        FilterDropdown<int?>(
          label: 'Интенсивность',
          value: q.intensity,
          items: [
            DropdownMenuItem(value: null, child: FilterDropdown.menuText('Любая')),
            for (var level = 1; level <= 5; level++)
              DropdownMenuItem(value: level, child: FilterDropdown.menuText('$level')),
          ],
          onChanged: (value) => _navigate(q.copyWith(intensity: value)),
        ),
        FilterChip(
          label: const Text('Показать удалённые'),
          selected: q.includeDeleted,
          onSelected: (value) => _navigate(q.copyWith(includeDeleted: value)),
        ),
      ],
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      onRetry: _notifier.load,
      pagination: PaginationBar(
        result: notifier.result,
        onPageChanged: (page) => _navigate(q.copyWith(page: page)),
        onSizeChanged: (size) => _navigate(q.copyWith(size: size)),
      ),
      body: compact
          ? ListView.builder(
              itemCount: notifier.result.items.length,
              itemBuilder: (context, index) {
                final item = notifier.result.items[index];
                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: notifier.selected.contains(item.id),
                      onChanged: (_) => notifier.toggleSelection(item.id),
                    ),
                    title: Text(item.name),
                    subtitle: Text('Интенсивность ${item.intensity}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: _actions(notifier, item)),
                    onTap: () => context.push('/flavors/${item.id}'),
                  ),
                );
              },
            )
          : EntityTable<Flavor>(
              items: notifier.result.items,
              idOf: (item) => item.id,
              selected: notifier.selected,
              onToggleSelect: notifier.toggleSelection,
              sortField: q.sortField,
              sortAscending: q.sortAscending,
              onSort: (field) => _navigate(
                q.copyWith(sortField: field, sortAscending: field == q.sortField ? !q.sortAscending : true),
              ),
              columns: [
                TableColumnSpec(label: 'Название', sortField: 'name', build: (item) => Text(item.name)),
                TableColumnSpec(
                  label: 'Интенсивность',
                  sortField: 'intensity',
                  numeric: true,
                  build: (item) => Text('${item.intensity}'),
                ),
                TableColumnSpec(label: 'Описание', sortField: 'description', build: (item) => Text(item.description)),
              ],
              actions: (item) => _actions(notifier, item),
            ),
    );
  }

  List<Widget> _actions(CatalogNotifier<Flavor, FlavorQuery> notifier, Flavor item) {
    return rowActions(
      onOpen: () => context.push('/flavors/${item.id}'),
      onEdit: () => context.push('/flavors/${item.id}/edit'),
      deleted: item.isDeleted,
      onRestore: () async {
        await notifier.restoreOne(item.id);
        _navigate(notifier.query);
      },
      onSoftDelete: () async {
        await notifier.softDeleteOne(item.id);
        _navigate(notifier.query);
      },
      onHardDelete: () async {
        await notifier.hardDeleteOne(item.id);
        _navigate(notifier.query);
      },
    );
  }
}
