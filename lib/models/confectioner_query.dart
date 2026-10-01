class ConfectionerQuery {
  final String search;
  final String? country;
  final String? specialty;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ConfectionerQuery({
    this.search = '',
    this.country,
    this.specialty,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  ConfectionerQuery copyWith({
    String? search,
    Object? country = _unset,
    Object? specialty = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ConfectionerQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      specialty: specialty == _unset ? this.specialty : specialty as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }
}
