import 'package:flutter/foundation.dart';

enum Environment {
  mock,
  real;

  /// Pass `--dart-define=ENV=mock|real` to override; otherwise release builds
  /// use the real API and debug/profile builds use the mock.
  static Environment get current =>
      switch (const String.fromEnvironment('ENV')) {
        'mock' => mock,
        'real' => real,
        _ => kReleaseMode ? real : mock,
      };

  static const mockBaseUrl = 'https://mock.daybook';

  static const realBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.daybook.dev',
  );
}
