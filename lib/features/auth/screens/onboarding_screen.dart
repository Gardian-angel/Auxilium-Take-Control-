import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  String _displayName = '';
  String _timezone = 'UTC';
  bool _loading = false;

  static const _timezones = [
    'UTC', 'America/New_York', 'America/Los_Angeles', 'Europe/London',
    'Europe/Paris', 'Asia/Jerusalem', 'Asia/Tokyo', 'Australia/Sydney',
  ];

  void _next() {
    if (_page < 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_page + 1) / 2,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withOpacity(0.15),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  _Step1(
                    onNameChanged: (v) => _displayName = v,
                    onTimezoneChanged: (v) => _timezone = v,
                    timezones: _timezones,
                  ),
                  const _Step2(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _loading ? null : _next,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_page < 1 ? 'Continue' : 'Get started'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1 extends StatelessWidget {
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onTimezoneChanged;
  final List<String> timezones;
  const _Step1({required this.onNameChanged, required this.onTimezoneChanged, required this.timezones});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('Tell us about yourself', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('We\'ll personalise your experience', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 40),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Display name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: timezones.first,
            decoration: const InputDecoration(labelText: 'Timezone', prefixIcon: Icon(Icons.schedule)),
            items: timezones.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
            onChanged: (v) { if (v != null) onTimezoneChanged(v); },
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  const _Step2();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_rounded, size: 80, color: AppColors.moodLove),
          const SizedBox(height: 32),
          Text('You\'re all set!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            'Start tracking your mood and take control of your wellbeing.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
