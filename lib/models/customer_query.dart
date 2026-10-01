class CustomerQuery {
  final String search;
  final bool? cardActive;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const CustomerQuery({
    this.search = '',
    this.cardActive,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  CustomerQuery copyWith({
    String? search,
    Object? cardActive = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return CustomerQuery(
      search: search ?? this.search,
      cardActive: cardActive == _unset ? this.cardActive : cardActive as bool?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }
}
