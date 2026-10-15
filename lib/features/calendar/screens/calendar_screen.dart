import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/device_calendar_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with WidgetsBindingObserver {
  CalendarAccess? _access;
  List<CalendarEventItem> _events = const [];
  bool _loading = true;

  DeviceCalendarService get _service => ref.read(deviceCalendarServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The user may have changed the permission in the Settings app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final access = await _service.currentAccess();
    final events = access == CalendarAccess.granted
        ? await _service.upcomingEvents()
        : const <CalendarEventItem>[];
    if (!mounted) return;
    setState(() {
      _access = access;
      _events = events;
      _loading = false;
    });
  }

  Future<void> _continue() async {
    setState(() => _loading = true);
    await _service.requestAccess();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : switch (_access!) {
              CalendarAccess.notAsked => _Explainer(onContinue: _continue),
              CalendarAccess.denied => const _AccessOff(),
              CalendarAccess.granted =>
                RefreshIndicator(onRefresh: _load, child: _EventList(events: _events)),
            },
    );
  }
}

/// Shown once, before the system prompt. The button only moves the user on;
/// the choice itself is made in the system dialog (App Review 5.1.1(iv)).
class _Explainer extends StatelessWidget {
  final VoidCallback onContinue;
  const _Explainer({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('See your week next to your moods',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'INPROV can show events from the calendars on this device, so you can '
            'spot how your schedule relates to how you feel. Events stay on your '
            'device and are never uploaded.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onContinue, child: const Text('Continue')),
          ),
        ],
      ),
    );
  }
}

class _AccessOff extends StatelessWidget {
  const _AccessOff();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 24),
          Text('Calendar access is off',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'This screen needs calendar access to show your events. '
            'You can turn it on in Settings at any time. Everything else in INPROV works without it.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(onPressed: openAppSettings, child: const Text('Open Settings')),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final List<CalendarEventItem> events;
  const _EventList({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No events in the next two weeks')),
        ],
      );
    }

    final dayFmt = DateFormat.MMMMEEEEd();
    final timeFmt = DateFormat.jm();
    final children = <Widget>[];
    DateTime? currentDay;
    for (final e in events) {
      final day = DateTime(e.start.year, e.start.month, e.start.day);
      if (day != currentDay) {
        currentDay = day;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(dayFmt.format(day),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ));
      }
      children.add(Card(
        child: ListTile(
          leading: const Icon(Icons.event_rounded),
          title: Text(e.title),
          subtitle: Text([
            e.allDay ? 'All day' : timeFmt.format(e.start.toLocal()),
            if (e.calendarName.isNotEmpty) e.calendarName,
          ].join(' · ')),
        ),
      ));
    }
    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}
