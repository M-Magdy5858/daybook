import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/versioned_collection.dart';
import 'package:dio/dio.dart';

class HabitRoutes {
  HabitRoutes(this._state)
    : _habits = VersionedCollection(
        items: _state.habits,
        name: 'Habit',
        validate: _validate,
      );
  final MockServerState _state;
  final VersionedCollection _habits;

  void register(MockRouter router) => router
    ..on('GET', '/habits', (req, _) => _list(req))
    ..on('GET', '/habits/:id', (_, p) => _habits.get(p['id']!))
    ..on('POST', '/habits', (req, _) => _habits.create(req))
    ..on('PATCH', '/habits/:id', (req, p) => _habits.update(req, p['id']!))
    ..on('DELETE', '/habits/:id', (_, p) => _habits.delete(p['id']!));

  /// `GET /habits?page=1&limit=20&updatedSince=<iso>`, sorted by name.
  Future<MockResponse> _list(RequestOptions req) async {
    final q = req.queryParameters;
    final items =
        _state.habits.values
            .where((h) => VersionedCollection.changedSince(h, q))
            .toList()
          ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return VersionedCollection.page(items, q);
  }

  static MockResponse? _validate(Map<String, dynamic> body) {
    final errors = <String, String>{
      if ('${body['name'] ?? ''}'.trim().isEmpty) 'name': 'Required',
      if ((body['weekdays'] as List? ?? const []).isEmpty)
        'weekdays': 'Pick at least one day',
    };
    return errors.isEmpty
        ? null
        : MockResponse(422, {'message': 'Validation failed', 'errors': errors});
  }
}
