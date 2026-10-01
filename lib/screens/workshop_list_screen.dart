import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/workshop.dart';
import '../models/workshop_query.dart';
import '../repositories/flavor_repository.dart';
import '../repositories/workshop_repository.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';
import '../widgets/catalog_frame.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/row_actions.dart';
import '../widgets/workshop_delete_guard.dart';

class WorkshopListScreen extends StatefulWidget {
  const WorkshopListScreen({super.key});

  @override
  State<WorkshopListScreen> createState() => _WorkshopListScreenState();
}

class _WorkshopListScreenState extends State<WorkshopListScreen> {
  bool _filtersExpanded = true;

  CatalogNotifier<Workshop, WorkshopQuery> get _notifier => context.read<CatalogNotifier<Workshop, WorkshopQuery>>();

  void _navigate(WorkshopQuery query) => context.go(workshopQueryToLocation(query));

  Future<void> _deleteSelected(CatalogNotifier<Workshop, WorkshopQuery> notifier) async {
    final ok = await confirmLogicalDelete(context, notifier.selected.length);
    if (!ok || !mounted) return;
    final done = await runWorkshopDelete(context, () => notifier.deleteSelected());
    if (done && mounted) _navigate(notifier.query);
  }

  Future<void> _guarded(Future<void> Function() action, CatalogNotifier<Workshop, WorkshopQuery> notifier) async {
    final done = await runWorkshopDelete(context, action);
    if (done && mounted) _navigate(notifier.query);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CatalogNotifier<Workshop, WorkshopQuery>>();
    final q = notifier.query;
    final compact = isCompactWidth(context);
    final flavors = context.read<FlavorRepository>().all;
    final cities = {...context.read<WorkshopRepository>().all.map((w) => w.city)}.toList()..sort();

    String flavorLabel(Workshop item) {
      if (item.flavorIds.isEmpty) return '—';
      return item.flavorIds
          .map((id) {
            for (final flavor in flavors) {
              if (flavor.id == id) return flavor.name;
            }
            return '?';
          })
          .join(', ');
    }

    return CatalogFrame(
      title: 'Цеха',
      onCreate: () => context.push('/workshops/new'),
      selectedCount: notifier.selected.length,
      onDeleteSelected: () => _deleteSelected(notifier),
      filtersExpanded: _filtersExpanded,
      onToggleFilters: () => setState(() => _filtersExpanded = !_filtersExpanded),
      filters: [
        SizedBox(
          width: 260,
          child: DebouncedSearchField(
            initialValue: q.search,
            label: 'Поиск по названию, городу или телефону',
            onChanged: (value) => _navigate(q.copyWith(search: value)),
          ),
        ),
        FilterDropdown<String?>(
          label: 'Город',
          value: q.city,
          items: [
            DropdownMenuItem(value: null, child: FilterDropdown.menuText('Все города')),
            for (final city in cities) DropdownMenuItem(value: city, child: FilterDropdown.menuText(city)),
          ],
          onChanged: (value) => _navigate(q.copyWith(city: value)),
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
                    subtitle: Text('${item.city} · ${item.phone}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: _actions(notifier, item)),
                    onTap: () => context.push('/workshops/${item.id}'),
                  ),
                );
              },
            )
          : EntityTable<Workshop>(
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
                TableColumnSpec(label: 'Город', sortField: 'city', build: (item) => Text(item.city)),
                TableColumnSpec(label: 'Телефон', sortField: 'phone', build: (item) => Text(item.phone)),
                TableColumnSpec(label: 'Вкусы', build: (item) => Text(flavorLabel(item))),
              ],
              actions: (item) => _actions(notifier, item),
            ),
    );
  }

  List<Widget> _actions(CatalogNotifier<Workshop, WorkshopQuery> notifier, Workshop item) {
    return rowActions(
      onOpen: () => context.push('/workshops/${item.id}'),
      onEdit: () => context.push('/workshops/${item.id}/edit'),
      deleted: item.isDeleted,
      onRestore: () async {
        await notifier.restoreOne(item.id);
        _navigate(notifier.query);
      },
      onSoftDelete: () => _guarded(() => notifier.softDeleteOne(item.id), notifier),
      onHardDelete: () => _guarded(() => notifier.hardDeleteOne(item.id), notifier),
    );
  }
}
