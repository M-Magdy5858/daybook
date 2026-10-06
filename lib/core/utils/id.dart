import 'dart:math';

final _random = Random.secure();

/// A random, client-generated id, so the same item created offline and sent
/// twice is still one item on the server.
String newId() => List.generate(
  16,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();
