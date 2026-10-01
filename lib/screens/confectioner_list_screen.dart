import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../routing/query_codec.dart';
import '../models/confectioner.dart';
import '../models/confectioner_query.dart';
import '../repositories/reference_repository.dart';
import '../repositories/workshop_repository.dart';
import '../state/confectioner_list_notifier.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_status_body.dart';
import '../widgets/pagination_bar.dart';

class ConfectionerListScreen extends StatefulWidget {
  const ConfectionerListScreen({super.key});

  @override
  State<ConfectionerListScreen> createState() => _ConfectionerListScreenState();
}

class _ConfectionerListScreenState extends State<ConfectionerListScreen> {
  bool _filtersExpanded = true;

  void _navigate(ConfectionerQuery query) {
    context.go(confectionerQueryToLocation(query));
  }

  Future<void> _confirmDeleteSelected(ConfectionerListNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить выбранных?'),
        content: Text('Логическое удаление (${notifier.selected.length} шт.)'),
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
    final notifier = context.watch<ConfectionerListNotifier>();
    final q = notifier.query;
    final compact = isCompactWidth(context);
    final references = context.watch<ReferenceRepository>();
    final workshopNames = {
      for (final workshop in context.read<WorkshopRepository>().all) workshop.id: workshop.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Кондитеры'),
        actions: [
          if (notifier.hasSelection)
            TextButton.icon(
              onPressed: () => _confirmDeleteSelected(notifier),
              icon: const Icon(Icons.delete_outline),
              label: Text('Удалить (${notifier.selected.length})'),
            ),
          IconButton(
            tooltip: 'Новый кондитер',
            onPressed: () => context.push('/confectioners/new'),
            icon: const Icon(Icons.add),
          ),
          IconButton(onPressed: () => context.go('/'), icon: const Icon(Icons.home)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
              children: [
                SizedBox(
                  width: 260,
                  child: DebouncedSearchField(
                    initialValue: q.search,
                    label: 'Поиск по фамилии или стране',
                    onChanged: (value) => _navigate(q.copyWith(search: value)),
                  ),
                ),
                FilterDropdown<String?>(
                  label: 'Страна',
                  value: q.country,
                  items: [
                    DropdownMenuItem(value: null, child: FilterDropdown.menuText('Все страны')),
                    for (final c in references.countries)
                      DropdownMenuItem(value: c, child: FilterDropdown.menuText(c)),
                  ],
                  onChanged: (value) => _navigate(q.copyWith(country: value)),
                ),
                FilterDropdown<String?>(
                  label: 'Специализация',
                  width: 240,
                  value: q.specialty,
                  items: [
                    DropdownMenuItem(value: null, child: FilterDropdown.menuText('Любая')),
                    for (final s in references.specialties)
                      DropdownMenuItem(value: s, child: FilterDropdown.menuText(s)),
                  ],
                  onChanged: (value) => _navigate(q.copyWith(specialty: value)),
                ),
                FilterChip(
                  label: const Text('Показать удалённых'),
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
                onRetry: () => context.read<ConfectionerListNotifier>().load(),
                child: Column(
                  children: [
                    Expanded(
                      child: compact
                          ? ListView.builder(
                              itemCount: notifier.result.items.length,
                              itemBuilder: (context, index) {
                                final c = notifier.result.items[index];
                                return Card(
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: notifier.selected.contains(c.id),
                                      onChanged: (_) => notifier.toggleSelection(c.id),
                                    ),
                                    title: Text(c.fullName),
                                    subtitle: Text('${c.country} · ${c.specialty} · ${workshopNames[c.workshopId] ?? '—'}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: _confectionerActions(context, notifier, c, _navigate),
                                    ),
                                    onTap: () => context.push('/confectioners/${c.id}'),
                                  ),
                                );
                              },
                            )
                          : EntityTable<Confectioner>(
                              items: notifier.result.items,
                              idOf: (c) => c.id,
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
                                TableColumnSpec(label: 'Фамилия', sortField: 'lastName', build: (c) => Text(c.lastName)),
                                TableColumnSpec(label: 'Имя', sortField: 'firstName', build: (c) => Text(c.firstName)),
                                TableColumnSpec(label: 'Страна', sortField: 'country', build: (c) => Text(c.country)),
                                TableColumnSpec(label: 'Специализация', sortField: 'specialty', build: (c) => Text(c.specialty)),
                                TableColumnSpec(label: 'Цех', build: (c) => Text(workshopNames[c.workshopId] ?? '—')),
                              ],
                              actions: (c) => _confectionerActions(context, notifier, c, _navigate),
                            ),
                    ),
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

List<Widget> _confectionerActions(
  BuildContext context,
  ConfectionerListNotifier notifier,
  Confectioner c,
  void Function(ConfectionerQuery query) onNavigate,
) {
  return [
    IconButton(
      tooltip: 'Карточка',
      icon: const Icon(Icons.open_in_new),
      onPressed: () => context.push('/confectioners/${c.id}'),
    ),
    IconButton(
      tooltip: 'Изменить',
      icon: const Icon(Icons.edit_outlined),
      onPressed: () => context.push('/confectioners/${c.id}/edit'),
    ),
    if (c.isDeleted)
      IconButton(
        tooltip: 'Восстановить',
        icon: const Icon(Icons.restore),
        onPressed: () async {
          await notifier.restoreOne(c.id);
          onNavigate(notifier.query);
        },
      )
    else ...[
      IconButton(
        tooltip: 'Логическое удаление',
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await notifier.softDeleteOne(c.id);
          onNavigate(notifier.query);
        },
      ),
      IconButton(
        tooltip: 'Удалить навсегда',
        icon: const Icon(Icons.delete_forever),
        onPressed: () async {
          await notifier.hardDeleteOne(c.id);
          onNavigate(notifier.query);
        },
      ),
    ],
  ];
}
