import 'package:daybook/core/network/mock/mock_response.dart';
import 'package:daybook/core/network/mock/mock_router.dart';
import 'package:daybook/core/network/mock/mock_server_state.dart';
import 'package:daybook/core/network/mock/versioned_collection.dart';

/// `/accounts`, `/categories` and `/transactions`.
class ExpenseRoutes {
  ExpenseRoutes(this._state);
  final MockServerState _state;

  void register(MockRouter router) {
    _collection(
      router,
      '/accounts',
      VersionedCollection(
        items: _state.accounts,
        name: 'Account',
        validate: (_) => null,
      ),
    );
    _collection(
      router,
      '/categories',
      VersionedCollection(
        items: _state.categories,
        name: 'Category',
        validate: (_) => null,
      ),
    );
    _collection(
      router,
      '/transactions',
      VersionedCollection(
        items: _state.transactions,
        name: 'Transaction',
        validate: _validateTransaction,
      ),
    );
  }

  void _collection(MockRouter router, String path, VersionedCollection c) =>
      router
        ..on('GET', path, (req, _) async {
          final q = req.queryParameters;
          return VersionedCollection.page([
            for (final item in c.items.values)
              if (VersionedCollection.changedSince(item, q)) item,
          ], q);
        })
        ..on('GET', '$path/:id', (_, p) => c.get(p['id']!))
        ..on('POST', path, (req, _) => c.create(req))
        ..on('PATCH', '$path/:id', (req, p) => c.update(req, p['id']!))
        ..on('DELETE', '$path/:id', (_, p) => c.delete(p['id']!));

  static MockResponse? _validateTransaction(Map<String, dynamic> body) {
    final amount = body['amountMinor'];
    return amount is int && amount > 0
        ? null
        : const MockResponse(422, {
            'message': 'Validation failed',
            'errors': {'amountMinor': 'Must be more than zero'},
          });
  }
}
