import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/flavor.dart';
import '../models/flavor_query.dart';
import '../routing/query_codec.dart';
import '../state/catalog_notifier.dart';
import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../widgets/api_feedback.dart';
import '../widgets/catalog_frame.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/record_card.dart';
import '../widgets/row_actions.dart';

class FlavorListScreen extends StatefulWidget {
  const FlavorListScreen({super.key});

  @override
  State<FlavorListScreen> createState() => _FlavorListScreenState();
}

class _FlavorListScreenState extends State<FlavorListScreen> {
  bool _filtersExpanded = true;

  CatalogNotifier<Flavor, FlavorQuery> get _notifier =>
      context.read<CatalogNotifier<Flavor, FlavorQuery>>();

  void _navigate(FlavorQuery query) => context.go(flavorQueryToLocation(query));

  Future<void> _deleteSelected(
    CatalogNotifier<Flavor, FlavorQuery> notifier,
  ) async {
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
    final manage = context.watch<AuthNotifier>().allows(
      AppAction.manageCatalog,
    );
    final restore = context.watch<AuthNotifier>().allows(AppAction.restore);
    final hard = context.watch<AuthNotifier>().allows(AppAction.hardDelete);
    return CatalogFrame(
      title: 'Вкусы',
      canCreate: manage,
      onCreate: () => context.push('/flavors/new'),
      selectedCount: notifier.selected.length,
      onDeleteSelected: () => _deleteSelected(notifier),
      filtersExpanded: _filtersExpanded,
      onToggleFilters: () =>
          setState(() => _filtersExpanded = !_filtersExpanded),
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
            DropdownMenuItem(
              value: null,
              child: FilterDropdown.menuText('Любая'),
            ),
            for (var level = 1; level <= 5; level++)
              DropdownMenuItem(
                value: level,
                child: FilterDropdown.menuText('$level'),
              ),
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
          ? CardBoard(
              itemCount: notifier.result.items.length,
              itemBuilder: (context, index) {
                final item = notifier.result.items[index];
                return RecordCard(
                  selected: notifier.selected.contains(item.id),
                  onSelected: (_) => notifier.toggleSelection(item.id),
                  title: item.name,
                  subtitle: 'Интенсивность ${item.intensity}',
                  onTap: () => context.push('/flavors/${item.id}'),
                  actions: _actions(
                    notifier,
                    item,
                    manage: manage,
                    restore: restore,
                    hard: hard,
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
                q.copyWith(
                  sortField: field,
                  sortAscending: field == q.sortField ? !q.sortAscending : true,
                ),
              ),
              columns: [
                TableColumnSpec(
                  label: 'Название',
                  sortField: 'name',
                  build: (item) => Text(item.name),
                ),
                TableColumnSpec(
                  label: 'Интенсивность',
                  sortField: 'intensity',
                  numeric: true,
                  build: (item) => Text('${item.intensity}'),
                ),
                TableColumnSpec(
                  label: 'Описание',
                  sortField: 'description',
                  build: (item) => Text(item.description),
                ),
              ],
              actions: (item) => _actions(
                notifier,
                item,
                manage: manage,
                restore: restore,
                hard: hard,
              ),
            ),
    );
  }

  List<Widget> _actions(
    CatalogNotifier<Flavor, FlavorQuery> notifier,
    Flavor item, {
    required bool manage,
    required bool restore,
    required bool hard,
  }) {
    return rowActions(
      canEdit: manage,
      canSoftDelete: manage,
      canRestore: restore,
      canHardDelete: hard,
      onOpen: () => context.push('/flavors/${item.id}'),
      onEdit: () => context.push('/flavors/${item.id}/edit'),
      deleted: item.isDeleted,
      onRestore: () => showFailure(context, () async {
        await notifier.restoreOne(item.id);
        _navigate(notifier.query);
      }),
      onSoftDelete: () => showFailure(context, () async {
        await notifier.softDeleteOne(item.id);
        _navigate(notifier.query);
      }),
      onHardDelete: () => showFailure(context, () async {
        await notifier.hardDeleteOne(item.id);
        _navigate(notifier.query);
      }),
    );
  }
}
