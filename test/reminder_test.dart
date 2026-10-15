import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inprov/core/services/reminder_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('nextInstanceOf picks today when the time is still ahead', () {
    final loc = tz.getLocation('Asia/Jerusalem');
    final now = tz.TZDateTime(loc, 2026, 10, 15, 9, 0);
    final next = nextInstanceOf(const TimeOfDay(hour: 20, minute: 30), now);
    expect(next, tz.TZDateTime(loc, 2026, 10, 15, 20, 30));
  });

  test('nextInstanceOf rolls over to tomorrow once the time has passed', () {
    final loc = tz.getLocation('Asia/Jerusalem');
    final now = tz.TZDateTime(loc, 2026, 10, 15, 20, 30);
    final next = nextInstanceOf(const TimeOfDay(hour: 20, minute: 30), now);
    expect(next, tz.TZDateTime(loc, 2026, 10, 16, 20, 30));
  });
}
