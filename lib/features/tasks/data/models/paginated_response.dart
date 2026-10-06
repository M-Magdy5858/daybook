/// One page of a list endpoint: `{items: [...], page, limit, total}`.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) => PaginatedResponse(
    items: (json['items'] as List)
        .map((e) => fromItem(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int,
    total: json['total'] as int,
  );

  final List<T> items;
  final int page;
  final int total;
}
