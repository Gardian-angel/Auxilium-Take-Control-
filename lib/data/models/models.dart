import 'package:cloud_firestore/cloud_firestore.dart';

enum EmotionType { joy, calm, sad, angry, anxious, tired, hope, love }

enum InprovPlan { free, premium, couples, teams, enterprise }

class MoodEntryModel {
  final String id;
  final String userId;
  final EmotionType emotion;
  final double satisfaction;
  final double intensity;
  final String? note;
  final DateTime createdAt;
  final bool synced;

  const MoodEntryModel({
    required this.id,
    required this.userId,
    required this.emotion,
    required this.satisfaction,
    required this.intensity,
    this.note,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'emotion': emotion.name,
        'satisfaction': satisfaction,
        'intensity': intensity,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'synced': synced,
      };

  factory MoodEntryModel.fromJson(Map<String, dynamic> j) => MoodEntryModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        emotion: EmotionType.values.byName(j['emotion'] as String),
        satisfaction: (j['satisfaction'] as num).toDouble(),
        intensity: (j['intensity'] as num).toDouble(),
        note: j['note'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        synced: j['synced'] as bool? ?? false,
      );
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final InprovPlan plan;
  final bool isNewUser;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.plan = InprovPlan.free,
    this.isNewUser = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String?,
      photoUrl: d['photoUrl'] as String?,
      plan: InprovPlan.values.byName(d['plan'] as String? ?? 'free'),
      isNewUser: d['isNewUser'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'plan': plan.name,
        'isNewUser': isNewUser,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class AppSettingsModel {
  final String language;
  final String timezone;
  final bool darkMode;
  final bool notificationsEnabled;
  final bool biometricEnabled;

  const AppSettingsModel({
    this.language = 'en',
    this.timezone = 'UTC',
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
  });

  Map<String, dynamic> toJson() => {
        'language': language,
        'timezone': timezone,
        'darkMode': darkMode,
        'notificationsEnabled': notificationsEnabled,
        'biometricEnabled': biometricEnabled,
      };

  factory AppSettingsModel.fromJson(Map<String, dynamic> j) => AppSettingsModel(
        language: j['language'] as String? ?? 'en',
        timezone: j['timezone'] as String? ?? 'UTC',
        darkMode: j['darkMode'] as bool? ?? false,
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? true,
        biometricEnabled: j['biometricEnabled'] as bool? ?? false,
      );
}
