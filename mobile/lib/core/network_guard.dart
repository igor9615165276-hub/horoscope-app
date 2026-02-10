import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkGuard extends StatefulWidget {
  final Widget child;

  const NetworkGuard({super.key, required this.child});

  @override
  State<NetworkGuard> createState() => _NetworkGuardState();
}

class _NetworkGuardState extends State<NetworkGuard> {
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();
    _checkNow();
    _sub = Connectivity().onConnectivityChanged.listen((_) => _checkNow());
  }

  Future<void> _checkNow() async {
    bool ok = false;
    try {
      final result = await InternetAddress.lookup('example.com');
      ok = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      ok = false;
    }
    if (mounted) {
      setState(() => _hasInternet = ok);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasInternet) {
      return const _NoInternetScreen();
    }
    return widget.child;
  }
}

class _NoInternetScreen extends StatelessWidget {
  const _NoInternetScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Подключение к сети интернет отсутствует',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ),
    );
  }
}
