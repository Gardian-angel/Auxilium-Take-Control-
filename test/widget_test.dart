import 'package:flutter_test/flutter_test.dart';
import 'package:inprov/data/models/models.dart';

void main() {
  test('MoodEntryModel survives a JSON round trip', () {
    final entry = MoodEntryModel(
      id: '1',
      userId: 'u1',
      emotion: EmotionType.calm,
      satisfaction: 7,
      intensity: 4,
      note: 'quiet morning',
      createdAt: DateTime.utc(2026, 10, 14),
    );

    final copy = MoodEntryModel.fromJson(entry.toJson());

    expect(copy.emotion, EmotionType.calm);
    expect(copy.satisfaction, 7);
    expect(copy.note, 'quiet morning');
    expect(copy.createdAt, entry.createdAt);
  });
}
