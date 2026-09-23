import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../repositories/auth_repository.dart';

final moodEntryRepositoryProvider = Provider<MoodEntryRepository>((ref) {
  return MoodEntryRepository(
    firestore: ref.watch(firestoreProvider),
    userId: ref.watch(authStateProvider).valueOrNull?.uid ?? '',
  );
});

class MoodEntryRepository {
  final FirebaseFirestore _db;
  final String _userId;
  final Box _box = Hive.box('moodLogs');
  static const _uuid = Uuid();

  MoodEntryRepository({required FirebaseFirestore firestore, required String userId})
      : _db = firestore,
        _userId = userId;

  Future<MoodEntryModel> addEntry({
    required EmotionType emotion,
    required double satisfaction,
    required double intensity,
    String? note,
  }) async {
    final entry = MoodEntryModel(
      id: _uuid.v4(),
      userId: _userId,
      emotion: emotion,
      satisfaction: satisfaction,
      intensity: intensity,
      note: note,
      createdAt: DateTime.now(),
    );
    await _box.put(entry.id, entry.toJson());
    _syncToFirestore(entry);
    return entry;
  }

  List<MoodEntryModel> getLocalEntries() {
    return _box.values
        .map((v) => MoodEntryModel.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<MoodEntryModel>> watchEntries() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('moodEntries')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MoodEntryModel.fromJson(d.data()))
            .toList());
  }

  Future<void> _syncToFirestore(MoodEntryModel entry) async {
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('moodEntries')
          .doc(entry.id)
          .set(entry.toJson());
      await _box.put(entry.id, entry.copyWith(synced: true).toJson());
    } catch (_) {
      // Will retry via sync queue
    }
  }
}

extension _Copy on MoodEntryModel {
  MoodEntryModel copyWith({bool? synced}) => MoodEntryModel(
        id: id,
        userId: userId,
        emotion: emotion,
        satisfaction: satisfaction,
        intensity: intensity,
        note: note,
        createdAt: createdAt,
        synced: synced ?? this.synced,
      );
}
