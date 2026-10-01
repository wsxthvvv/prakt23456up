class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  PageResult.empty()
      : items = <T>[],
        page = 1,
        size = 10,
        total = 0;
}

PageResult<T> paginate<T>(List<T> rows, int page, int size) {
  final total = rows.length;
  final safePage = page < 1 ? 1 : page;
  final safeSize = size < 1 ? 10 : size;
  final from = (safePage - 1) * safeSize;
  final to = (from + safeSize) > total ? total : (from + safeSize);
  final items = from >= total ? <T>[] : rows.sublist(from, to);
  return PageResult(items: items, page: safePage, size: safeSize, total: total);
}
