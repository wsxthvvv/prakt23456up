import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/customer.dart';
import '../models/customer_query.dart';
import '../routing/query_codec.dart';
import '../auth/access_policy.dart';
import '../auth/auth_notifier.dart';
import '../state/catalog_notifier.dart';
import '../widgets/api_feedback.dart';
import '../widgets/catalog_frame.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/row_actions.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  bool _filtersExpanded = true;

  CatalogNotifier<Customer, CustomerQuery> get _notifier => context.read<CatalogNotifier<Customer, CustomerQuery>>();

  void _navigate(CustomerQuery query) => context.go(customerQueryToLocation(query));

  Future<void> _deleteSelected(CatalogNotifier<Customer, CustomerQuery> notifier) async {
    final ok = await confirmLogicalDelete(context, notifier.selected.length);
    if (ok && mounted) {
      await notifier.deleteSelected();
      _navigate(notifier.query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CatalogNotifier<Customer, CustomerQuery>>();
    final q = notifier.query;
    final compact = isCompactWidth(context);
    final manage = context.watch<AuthNotifier>().allows(AppAction.manageCustomers);
    final restore = context.watch<AuthNotifier>().allows(AppAction.restore);
    final hard = context.watch<AuthNotifier>().allows(AppAction.hardDelete);
    return CatalogFrame(
      title: 'Покупатели',
      canCreate: manage,
      onCreate: () => context.push('/customers/new'),
      selectedCount: notifier.selected.length,
      onDeleteSelected: () => _deleteSelected(notifier),
      filtersExpanded: _filtersExpanded,
      onToggleFilters: () => setState(() => _filtersExpanded = !_filtersExpanded),
      filters: [
        SizedBox(
          width: 280,
          child: DebouncedSearchField(
            initialValue: q.search,
            label: 'Поиск по имени или почте',
            onChanged: (value) => _navigate(q.copyWith(search: value)),
          ),
        ),
        FilterDropdown<bool?>(
          label: 'Карта',
          value: q.cardActive,
          items: [
            DropdownMenuItem(value: null, child: FilterDropdown.menuText('Все')),
            DropdownMenuItem(value: true, child: FilterDropdown.menuText('Только активные')),
            DropdownMenuItem(value: false, child: FilterDropdown.menuText('Только неактивные')),
          ],
          onChanged: (value) => _navigate(q.copyWith(cardActive: value)),
        ),
        FilterChip(
          label: const Text('Показать удалённых'),
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
                    title: Text(item.fullName),
                    subtitle: Text(item.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _actions(notifier, item, manage: manage, restore: restore, hard: hard),
                    ),
                    onTap: () => context.push('/customers/${item.id}'),
                  ),
                );
              },
            )
          : EntityTable<Customer>(
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
                TableColumnSpec(label: 'Фамилия', sortField: 'lastName', build: (item) => Text(item.lastName)),
                TableColumnSpec(label: 'Имя', sortField: 'firstName', build: (item) => Text(item.firstName)),
                TableColumnSpec(label: 'Почта', sortField: 'email', build: (item) => Text(item.email)),
                TableColumnSpec(
                  label: 'Скидка, %',
                  sortField: 'discount',
                  numeric: true,
                  build: (item) => Text('${item.loyaltyCard.discountPercent}'),
                ),
                TableColumnSpec(
                  label: 'Карта',
                  build: (item) => Text(item.loyaltyCard.active ? item.loyaltyCard.number : 'неактивна'),
                ),
              ],
              actions: (item) => _actions(notifier, item, manage: manage, restore: restore, hard: hard),
            ),
    );
  }

  List<Widget> _actions(
    CatalogNotifier<Customer, CustomerQuery> notifier,
    Customer item, {
    required bool manage,
    required bool restore,
    required bool hard,
  }) {
    return rowActions(
      canEdit: manage,
      canSoftDelete: manage,
      canRestore: restore,
      canHardDelete: hard,
      onOpen: () => context.push('/customers/${item.id}'),
      onEdit: () => context.push('/customers/${item.id}/edit'),
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
