import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final deviceCalendarServiceProvider =
    Provider<DeviceCalendarService>((ref) => DeviceCalendarService());

enum CalendarAccess {
  /// The system prompt has never been shown.
  notAsked,
  granted,

  /// The user declined the system prompt; only the Settings app can change it.
  denied,
}

class CalendarEventItem {
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String calendarName;

  const CalendarEventItem({
    required this.title,
    required this.start,
    this.end,
    required this.allDay,
    required this.calendarName,
  });
}

/// Reads the calendars on the device (EventKit on iOS, CalendarContract on
/// Android). The system permission prompt is only shown from [requestAccess],
/// which the UI calls when the user opens the calendar feature.
class DeviceCalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  final Box _settings = Hive.box('settings');

  static const _askedKey = 'calendarPermissionAsked';

  Future<CalendarAccess> currentAccess() async {
    final has = await _plugin.hasPermissions();
    if (has.isSuccess && (has.data ?? false)) return CalendarAccess.granted;
    final asked = _settings.get(_askedKey, defaultValue: false) as bool;
    return asked ? CalendarAccess.denied : CalendarAccess.notAsked;
  }

  Future<CalendarAccess> requestAccess() async {
    await _settings.put(_askedKey, true);
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false)
        ? CalendarAccess.granted
        : CalendarAccess.denied;
  }

  Future<List<CalendarEventItem>> upcomingEvents({int days = 14}) async {
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return const [];

    final start = DateTime.now();
    final end = start.add(Duration(days: days));
    final items = <CalendarEventItem>[];
    for (final cal in calendars.data!) {
      if (cal.id == null) continue;
      final events = await _plugin.retrieveEvents(
        cal.id,
        RetrieveEventsParams(startDate: start, endDate: end),
      );
      for (final e in events.data ?? const <Event>[]) {
        if (e.start == null) continue;
        items.add(CalendarEventItem(
          title: (e.title?.trim().isNotEmpty ?? false) ? e.title! : 'Untitled event',
          start: e.start!,
          end: e.end,
          allDay: e.allDay ?? false,
          calendarName: cal.name ?? '',
        ));
      }
    }
    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }
}
