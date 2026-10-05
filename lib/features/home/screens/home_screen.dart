import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/mood_entry_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void _openCheckIn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CheckInSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CheckInCard(onTap: _openCheckIn),
            const SizedBox(height: 16),
            const _StreakBanner(),
            const SizedBox(height: 16),
            const _RecentHistory(),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CheckInCard({required this.onTap});

  static const _emotions = [
    (EmotionType.joy, '😄', 'Joy', AppColors.moodJoy),
    (EmotionType.calm, '😌', 'Calm', AppColors.moodCalm),
    (EmotionType.sad, '😢', 'Sad', AppColors.moodSad),
    (EmotionType.angry, '😠', 'Angry', AppColors.moodAngry),
    (EmotionType.anxious, '😰', 'Anxious', AppColors.moodAnxious),
    (EmotionType.tired, '😴', 'Tired', AppColors.moodTired),
    (EmotionType.hope, '🌱', 'Hope', AppColors.moodHope),
    (EmotionType.love, '❤️', 'Love', AppColors.moodLove),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: _emotions.map((e) {
                return InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: e.$4.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.$2, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(e.$3, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          const Text('🔥', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('7-day streak!', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('Keep it up', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ]),
        ]),
      ),
    );
  }
}

class _RecentHistory extends ConsumerWidget {
  const _RecentHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(moodEntryRepositoryProvider);
    final entries = repo.getLocalEntries();

    if (entries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No check-ins yet. Start above!')),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent check-ins', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...entries.take(5).map((e) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e.emotion.name),
            subtitle: Text(e.createdAt.toLocal().toString().substring(0, 16)),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${(e.satisfaction * 10).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Text('satisfaction', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _CheckInSheet extends ConsumerStatefulWidget {
  const _CheckInSheet();

  @override
  ConsumerState<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<_CheckInSheet> {
  EmotionType? _emotion;
  double _satisfaction = 0.5;
  double _intensity = 0.5;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_emotion == null) return;
    setState(() => _saving = true);
    final repo = ref.read(moodEntryRepositoryProvider);
    await repo.addEntry(
      emotion: _emotion!,
      satisfaction: _satisfaction,
      intensity: _intensity,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Log your mood', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Satisfaction'),
          Slider(value: _satisfaction, onChanged: (v) => setState(() => _satisfaction = v)),
          const Text('Intensity'),
          Slider(value: _intensity, onChanged: (v) => setState(() => _intensity = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
