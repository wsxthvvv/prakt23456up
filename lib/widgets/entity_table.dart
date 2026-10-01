import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final dataColumns = <DataColumn>[
      if (onToggleSelect != null)
        const DataColumn(label: SizedBox(width: 48, child: Text(''))),
      for (final col in columns)
        DataColumn(
          numeric: col.numeric,
          onSort: col.sortField != null && onSort != null ? (_, _) => onSort!(col.sortField!) : null,
          label: Text(col.label),
        ),
      if (actions != null) const DataColumn(label: Text('Действия')),
    ];

    final rows = <DataRow>[
      for (final item in items)
        DataRow(
          selected: selected.contains(idOf(item)),
          cells: [
            if (onToggleSelect != null)
              DataCell(
                Checkbox(
                  value: selected.contains(idOf(item)),
                  onChanged: (_) => onToggleSelect!(idOf(item)),
                ),
              ),
            for (final col in columns) DataCell(col.build(item)),
            if (actions != null) DataCell(Row(mainAxisSize: MainAxisSize.min, children: actions!(item))),
          ],
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 32),
          child: DataTable(
            sortColumnIndex: _sortColumnIndex(),
            sortAscending: sortAscending,
            columns: dataColumns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  int? _sortColumnIndex() {
    if (sortField == null) return null;
    var index = onToggleSelect != null ? 1 : 0;
    for (final col in columns) {
      if (col.sortField == sortField) return index;
      index++;
    }
    return null;
  }
}
