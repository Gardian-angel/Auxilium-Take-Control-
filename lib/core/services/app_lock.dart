import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

/// Optional Face ID / Touch ID / fingerprint lock for the journal.
/// Off by default; turned on from Settings › Security.
abstract final class AppLock {
  static const _key = 'appLockEnabled';
  static final _auth = LocalAuthentication();

  static ValueListenable<Box> get listenable =>
      Hive.box('settings').listenable(keys: [_key]);

  static bool get enabled => Hive.box('settings').get(_key, defaultValue: false) as bool;

  static Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Turning the lock on requires one successful scan, so a user can't lock
  /// themselves out with biometrics that don't work.
  static Future<bool> setEnabled(bool value) async {
    if (value && !await authenticate('Confirm to turn on the INPROV lock')) return false;
    await Hive.box('settings').put(_key, value);
    return true;
  }
}

/// Covers the app until the user authenticates, at launch and whenever the
/// app comes back from the background.
class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late bool _locked = AppLock.enabled;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The biometric sheet itself pauses the app, so ignore lifecycle events
    // while it is showing.
    if (_authenticating) return;
    if (state == AppLifecycleState.paused && AppLock.enabled) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final ok = await AppLock.authenticate('Unlock INPROV');
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text('INPROV is locked',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _unlock,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
