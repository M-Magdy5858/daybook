import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityService {
  /// Emits true when the device gets a network connection, false when it
  /// loses it. Being on Wi-Fi doesn't prove the internet works; a successful
  /// request does.
  Stream<bool> get onlineChanges;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();
  final Connectivity _connectivity;

  @override
  Stream<bool> get onlineChanges => _connectivity.onConnectivityChanged.map(
    (results) => !results.contains(ConnectivityResult.none),
  );
}
