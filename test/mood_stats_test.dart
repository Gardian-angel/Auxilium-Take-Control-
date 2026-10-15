import 'package:flutter_test/flutter_test.dart';
import 'package:inprov/data/models/models.dart';
import 'package:inprov/features/analytics/screens/analytics_screen.dart';

MoodEntryModel _entry(DateTime at, EmotionType emotion, double satisfaction) => MoodEntryModel(
      id: at.toIso8601String(),
      userId: 'u',
      emotion: emotion,
      satisfaction: satisfaction,
      intensity: 0.5,
      createdAt: at,
    );

void main() {
  test('MoodStats summarises the last 7 days only', () {
    final now = DateTime(2026, 10, 15, 12);
    final stats = MoodStats.fromEntries([
      _entry(DateTime(2026, 10, 15, 9), EmotionType.calm, 0.8),
      _entry(DateTime(2026, 10, 15, 18), EmotionType.calm, 0.4),
      _entry(DateTime(2026, 10, 12, 9), EmotionType.joy, 0.9),
      _entry(DateTime(2026, 10, 1, 9), EmotionType.sad, 0.1), // too old
    ], now);

    expect(stats.days.length, 7);
    expect(stats.days.last, DateTime(2026, 10, 15));
    expect(stats.activeDays, 2);
    expect(stats.dailySatisfaction.last, closeTo(0.6, 1e-9));
    expect(stats.dailySatisfaction[3], closeTo(0.9, 1e-9));
    expect(stats.dailySatisfaction.first, isNull);
    expect(stats.avgSatisfaction, closeTo(0.7, 1e-9));
    expect(stats.topEmotion, EmotionType.calm);
  });
}
