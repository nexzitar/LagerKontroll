import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity checker
abstract class NetworkInfo {
  /// Check if device has internet connection
  Future<bool> get isConnected;
  
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged;
}

/// Implementation of NetworkInfo using connectivity_plus package
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return _isConnectionAvailable(result);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return connectivity.onConnectivityChanged.map(_isConnectionAvailable);
  }

  /// Check if the connection result indicates internet availability
  bool _isConnectionAvailable(List<ConnectivityResult> results) {
    // If any connection is available (mobile, wifi, ethernet), return true
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }
}
