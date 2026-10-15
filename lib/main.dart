import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'core/navigation/app_router.dart';
import 'core/services/app_lock.dart';
import 'core/theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  await Future.wait([
    Hive.openBox('moodLogs'),
    Hive.openBox('syncQueue'),
    Hive.openBox('settings'),
    Hive.openBox('spaces'),
  ]);

  await _configurePurchases();

  runApp(const ProviderScope(child: InprovApp()));
}

// RevenueCat public SDK keys, passed at build time:
//   flutter build ipa --dart-define=REVENUECAT_APPLE_KEY=appl_...
//   flutter build appbundle --dart-define=REVENUECAT_GOOGLE_KEY=goog_...
// Without a key, purchases stay disabled instead of crashing on launch.
const _revenueCatAppleKey = String.fromEnvironment('REVENUECAT_APPLE_KEY');
const _revenueCatGoogleKey = String.fromEnvironment('REVENUECAT_GOOGLE_KEY');

Future<void> _configurePurchases() async {
  if (kIsWeb) return;
  final key = switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _revenueCatAppleKey,
    TargetPlatform.android => _revenueCatGoogleKey,
    _ => '',
  };
  if (key.isEmpty) return;
  await Purchases.configure(PurchasesConfiguration(key));
}

class InprovApp extends ConsumerWidget {
  const InprovApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'INPROV',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AppLockGate(child: child!),
      debugShowCheckedModeBanner: false,
    );
  }
}
