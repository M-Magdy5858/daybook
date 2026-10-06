import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/versioned_collection.dart';
import 'package:dio/dio.dart';

class EventRoutes {
  EventRoutes(this._state)
    : _events = VersionedCollection(
        items: _state.events,
        name: 'Event',
        validate: _validate,
      );
  final MockServerState _state;
  final VersionedCollection _events;

  void register(MockRouter router) => router
    ..on('GET', '/events', (req, _) => _list(req))
    ..on('GET', '/events/:id', (_, p) => _events.get(p['id']!))
    ..on('POST', '/events', (req, _) => _events.create(req))
    ..on('PATCH', '/events/:id', (req, p) => _events.update(req, p['id']!))
    ..on('DELETE', '/events/:id', (_, p) => _events.delete(p['id']!));

  /// `GET /events?page=1&limit=20&updatedSince=<iso>`, sorted by start.
  Future<MockResponse> _list(RequestOptions req) async {
    final q = req.queryParameters;
    final items =
        _state.events.values
            .where((e) => VersionedCollection.changedSince(e, q))
            .toList()
          ..sort((a, b) => '${a['start']}'.compareTo('${b['start']}'));
    return VersionedCollection.page(items, q);
  }

  static MockResponse? _validate(Map<String, dynamic> body) {
    final errors = <String, String>{
      if ('${body['title'] ?? ''}'.trim().isEmpty) 'title': 'Required',
      if (!DateTime.parse(
        '${body['end']}',
      ).isAfter(DateTime.parse('${body['start']}')))
        'end': 'Must be after the start',
    };
    return errors.isEmpty
        ? null
        : MockResponse(422, {'message': 'Validation failed', 'errors': errors});
  }
}
