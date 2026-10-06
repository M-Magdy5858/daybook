import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/versioned_collection.dart';
import 'package:dio/dio.dart';

class TaskRoutes {
  TaskRoutes(this._state)
    : _tasks = VersionedCollection(
        items: _state.tasks,
        name: 'Task',
        validate: _validate,
      );
  final MockServerState _state;
  final VersionedCollection _tasks;

  void register(MockRouter router) => router
    ..on('GET', '/tasks', (req, _) => _list(req))
    ..on('GET', '/tasks/:id', (_, p) => _tasks.get(p['id']!))
    ..on('POST', '/tasks', (req, _) => _tasks.create(req))
    ..on('PATCH', '/tasks/:id', (req, p) => _tasks.update(req, p['id']!))
    ..on('DELETE', '/tasks/:id', (_, p) => _tasks.delete(p['id']!));

  /// `GET /tasks?page=1&limit=20&status=active&sort=dueDate&q=milk&updatedSince=<iso>`
  Future<MockResponse> _list(RequestOptions req) async {
    final q = req.queryParameters;
    final search = '${q['q'] ?? ''}'.toLowerCase();

    final items = _state.tasks.values.where((t) {
      final done = t['completedAt'] != null;
      final statusOk = switch (q['status']) {
        'active' => !done,
        'completed' => done,
        _ => true,
      };
      final searchOk =
          search.isEmpty || '${t['title']}'.toLowerCase().contains(search);
      return statusOk && searchOk && VersionedCollection.changedSince(t, q);
    }).toList()..sort(_comparator('${q['sort'] ?? 'position'}'));

    return VersionedCollection.page(items, q);
  }

  static MockResponse? _validate(Map<String, dynamic> body) {
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
