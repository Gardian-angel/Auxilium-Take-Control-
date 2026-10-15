import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// RevenueCat entitlement that unlocks Premium.
const premiumEntitlement = 'premium';

// Legal links shown next to the subscription, required by App Review 3.1.2.
//   flutter build ipa --dart-define=PRIVACY_POLICY_URL=https://...
const _termsUrl = String.fromEnvironment(
  'TERMS_URL',
  defaultValue: 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
);
const _privacyUrl = String.fromEnvironment('PRIVACY_POLICY_URL');

bool get _isApple => defaultTargetPlatform == TargetPlatform.iOS;
String get _account => _isApple ? 'Apple ID' : 'Google account';
String get _store => _isApple ? 'App Store' : 'Google Play';

/// Native subscription screen. Products and prices come from the store via
/// RevenueCat's current offering, so nothing here hard-codes a price.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  List<Package> _packages = const [];
  Package? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!await Purchases.isConfigured) {
        throw StateError('Purchases are not available in this build.');
      }
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? const <Package>[];
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _selected = packages.isEmpty ? null : packages.first;
        _error = packages.isEmpty ? 'No subscriptions are available right now.' : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is StateError ? e.message : 'Could not load subscriptions. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _purchase() async {
    final pkg = _selected;
    if (pkg == null) return;
    setState(() => _busy = true);
    try {
      final result = await Purchases.purchase(PurchaseParams.package(pkg));
      _finish(result.customerInfo, success: 'Welcome to Premium!');
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) != PurchasesErrorCode.purchaseCancelledError) {
        _toast(e.message ?? 'Purchase failed.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active.containsKey(premiumEntitlement)) {
        _finish(info, success: 'Your Premium subscription was restored.');
      } else {
        _toast('No active subscription was found for this $_account.');
      }
    } on PlatformException catch (e) {
      _toast(e.message ?? 'Restore failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish(CustomerInfo info, {required String success}) {
    if (!mounted) return;
    if (info.entitlements.active.containsKey(premiumEntitlement)) {
      _toast(success);
      Navigator.of(context).pop(true);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('INPROV Premium')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(Icons.workspace_premium_rounded, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Go deeper with Premium',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  for (final f in const [
                    'Advanced mood insights and trends',
                    'Calendar view alongside your moods',
                    'Share progress with a professional you choose',
                    'Personal emotion board and statistics',
                  ])
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
                      title: Text(f),
                    ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  for (final p in _packages)
                    _PackageTile(
                      package: p,
                      selected: identical(p, _selected),
                      onTap: () => setState(() => _selected = p),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy || _selected == null ? null : _purchase,
                    child: _busy
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Subscribe'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _restore,
                    child: const Text('Restore purchases'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment is charged to your $_account at confirmation of purchase. '
                    'The subscription renews automatically at the same price unless it is '
                    'cancelled at least 24 hours before the end of the current period. '
                    'You can manage or cancel it in your $_store account settings.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => launchUrl(Uri.parse(_termsUrl)),
                        child: const Text('Terms of Use'),
                      ),
                      if (_privacyUrl.isNotEmpty)
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse(_privacyUrl)),
                          child: const Text('Privacy Policy'),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final Package package;
  final bool selected;
  final VoidCallback onTap;
  const _PackageTile({required this.package, required this.selected, required this.onTap});

  String get _period => switch (package.packageType) {
        PackageType.monthly => 'per month',
        PackageType.annual => 'per year',
        PackageType.weekly => 'per week',
        PackageType.sixMonth => 'every 6 months',
        PackageType.threeMonth => 'every 3 months',
        PackageType.twoMonth => 'every 2 months',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(product.title.isNotEmpty ? product.title : 'Premium'),
        subtitle: product.description.isNotEmpty ? Text(product.description) : null,
        trailing: Text('${product.priceString} $_period'.trim(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
