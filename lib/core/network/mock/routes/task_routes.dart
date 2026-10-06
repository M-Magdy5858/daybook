import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:dio/dio.dart';

class TaskRoutes {
  TaskRoutes(this._state);
  final MockServerState _state;

  void register(MockRouter router) => router
    ..on('GET', '/tasks', (req, _) => _list(req))
    ..on('GET', '/tasks/:id', (_, p) => _get(p['id']!))
    ..on('POST', '/tasks', (req, _) => _create(req))
    ..on('PATCH', '/tasks/:id', (req, p) => _update(req, p['id']!))
    ..on('DELETE', '/tasks/:id', (_, p) => _delete(p['id']!));

  /// `GET /tasks?page=1&limit=20&status=active&sort=dueDate&q=milk&updatedSince=<iso>`
  Future<MockResponse> _list(RequestOptions req) async {
    final q = req.queryParameters;
    final page = int.tryParse('${q['page']}') ?? 1;
    final limit = int.tryParse('${q['limit']}') ?? 20;
    final search = '${q['q'] ?? ''}'.toLowerCase();
    final since = DateTime.tryParse('${q['updatedSince']}');

    final items = _state.tasks.values.where((t) {
      final done = t['completedAt'] != null;
      final statusOk = switch (q['status']) {
        'active' => !done,
        'completed' => done,
        _ => true,
      };
      final searchOk =
          search.isEmpty || '${t['title']}'.toLowerCase().contains(search);
      final sinceOk =
          since == null || DateTime.parse('${t['updatedAt']}').isAfter(since);
      return statusOk && searchOk && sinceOk;
    }).toList()..sort(_comparator('${q['sort'] ?? 'position'}'));

    final start = ((page - 1) * limit).clamp(0, items.length);
    final end = (start + limit).clamp(0, items.length);
    return MockResponse(200, {
      'items': items.sublist(start, end),
      'page': page,
      'limit': limit,
      'total': items.length,
    });
  }

  Future<MockResponse> _get(String id) async {
    final task = _state.tasks[id];
    return task == null
        ? const MockResponse(404, {'message': 'Task not found'})
        : MockResponse(200, task);
  }

  /// Idempotent: the id is made by the client, so sending the same create
  /// twice returns the task that already exists.
  Future<MockResponse> _create(RequestOptions req) async {
    final body = Map<String, dynamic>.from(req.data as Map);
    final invalid = _validate(body);
    if (invalid != null) return invalid;

    final existing = _state.tasks[body['id']];
    if (existing != null) return MockResponse(200, existing);

    final task = {...body, 'version': 1};
    _state.tasks[task['id'] as String] = task;
    return MockResponse(201, task);
  }

  /// 409 with the server's copy when the client's version is out of date.
  Future<MockResponse> _update(RequestOptions req, String id) async {
    final current = _state.tasks[id];
    if (current == null) {
      return const MockResponse(404, {'message': 'Task not found'});
    }
    final body = Map<String, dynamic>.from(req.data as Map);
    final invalid = _validate(body);
    if (invalid != null) return invalid;

    final clientVersion = body['version'] as int? ?? 0;
    if ((current['version'] as int) > clientVersion) {
      return MockResponse(409, {
        'message': 'This task was changed elsewhere',
        'task': current,
      });
    }
    final task = {
      ...current,
      ...body,
      'id': id,
      'version': (current['version'] as int) + 1,
    };
    _state.tasks[id] = task;
    return MockResponse(200, task);
  }

  Future<MockResponse> _delete(String id) async {
    _state.tasks.remove(id);
    return const MockResponse(204);
  }

  MockResponse? _validate(Map<String, dynamic> body) {
    final title = '${body['title'] ?? ''}'.trim();
    return title.isEmpty
        ? const MockResponse(422, {
            'message': 'Validation failed',
            'errors': {'title': 'Required'},
          })
        : null;
  }

  static int Function(Map<String, dynamic>, Map<String, dynamic>) _comparator(
    String sort,
  ) => switch (sort) {
    'dueDate' => (a, b) => '${a['dueDate'] ?? '~'}'.compareTo(
      '${b['dueDate'] ?? '~'}',
    ),
    'priority' => (a, b) => _weight(b).compareTo(_weight(a)),
    'createdAt' => (a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'),
    _ => (a, b) => (a['position'] as int).compareTo(b['position'] as int),
  };

  static int _weight(Map<String, dynamic> t) =>
      const {'low': 1, 'medium': 2, 'high': 3}[t['priority']] ?? 2;
}
