import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:dio/dio.dart';

/// The parts every synced mock collection shares: get, idempotent create,
/// versioned update (409 on a stale version), delete, and paging.
class VersionedCollection {
  VersionedCollection({
    required this.items,
    required this.name,
    required this.validate,
  });

  /// JSON maps keyed by id.
  final Map<String, Map<String, dynamic>> items;

  /// For messages, e.g. `'Task'`.
  final String name;

  /// A 422 response, or `null` if [body] is valid.
  final MockResponse? Function(Map<String, dynamic> body) validate;

  Future<MockResponse> get(String id) async {
    final item = items[id];
    return item == null ? _notFound : MockResponse(200, item);
  }

  /// Idempotent: the id is made by the client, so sending the same create
  /// twice returns the item that already exists.
  Future<MockResponse> create(RequestOptions req) async {
    final body = Map<String, dynamic>.from(req.data as Map);
    final invalid = validate(body);
    if (invalid != null) return invalid;

    final existing = items[body['id']];
    if (existing != null) return MockResponse(200, existing);

    final item = {...body, 'version': 1};
    items[item['id'] as String] = item;
    return MockResponse(201, item);
  }

  /// 409 with the server's copy when the client's version is out of date.
  Future<MockResponse> update(RequestOptions req, String id) async {
    final current = items[id];
    if (current == null) return _notFound;
    final body = Map<String, dynamic>.from(req.data as Map);
    final invalid = validate(body);
    if (invalid != null) return invalid;

    final clientVersion = body['version'] as int? ?? 0;
    if ((current['version'] as int) > clientVersion) {
      return MockResponse(409, {
        'message': 'This ${name.toLowerCase()} was changed elsewhere',
        'item': current,
      });
    }
    final item = {
      ...current,
      ...body,
      'id': id,
      'version': (current['version'] as int) + 1,
    };
    items[id] = item;
    return MockResponse(200, item);
  }

  Future<MockResponse> delete(String id) async {
    items.remove(id);
    return const MockResponse(204);
  }

  /// One page of [list] as `{items, page, limit, total}`.
  static MockResponse page(
    List<Map<String, dynamic>> list,
    Map<String, dynamic> query,
  ) {
    final page = int.tryParse('${query['page']}') ?? 1;
    final limit = int.tryParse('${query['limit']}') ?? 20;
    final start = ((page - 1) * limit).clamp(0, list.length);
    final end = (start + limit).clamp(0, list.length);
    return MockResponse(200, {
      'items': list.sublist(start, end),
      'page': page,
      'limit': limit,
      'total': list.length,
    });
  }

  /// Whether [item] changed after the `updatedSince` query parameter.
  static bool changedSince(
    Map<String, dynamic> item,
    Map<String, dynamic> query,
  ) {
    final since = DateTime.tryParse('${query['updatedSince']}');
    return since == null ||
        DateTime.parse('${item['updatedAt']}').isAfter(since);
  }

  MockResponse get _notFound =>
      MockResponse(404, {'message': '$name not found'});
}
