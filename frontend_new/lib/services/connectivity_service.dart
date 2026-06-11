import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize({required VoidCallback onReconnect}) async {
    if (kIsWeb) {
      _isOnline = true;
      return;
    }

    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      if (wasOffline && _isOnline) {
        onReconnect();
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
