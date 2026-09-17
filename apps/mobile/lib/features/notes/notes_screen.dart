// 🟣 NIMMY — Notes Screen
// ========================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = [
      _NoteData('Meeting Notes', 'Discussed the new Nimmy AI features...', NimmyColors.purple, true, '2 min ago'),
      _NoteData('Project Ideas', '1. Voice-first interface\n2. Smart scheduling\n3. Context-aware reminders', NimmyColors.cyan, false, '1 hour ago'),
      _NoteData('Architecture Plan', 'Flutter for mobile, Next.js for web, Python for AI...', NimmyColors.amber, true, '3 hours ago'),
      _NoteData('Shopping List', '- Coffee beans\n- Notebooks\n- USB-C cable', NimmyColors.green, false, 'Yesterday'),
      _NoteData('Book Recommendations', 'Deep Work, Atomic Habits, The Design of Everyday Things', NimmyColors.pink, false, '2 days ago'),
      _NoteData('Workout Routine', 'Mon: Upper body\nTue: Cardio\nWed: Lower body...', NimmyColors.red, false, '3 days ago'),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notes', style: Theme.of(context).textTheme.headlineLarge),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NimmyColors.purpleDark, NimmyColors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: NimmyColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NimmyColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: NimmyColors.textMuted, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Search notes...',
                    style: TextStyle(
                      fontSize: 15,
                      color: NimmyColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes grid (masonry-like)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  return _NoteCard(note: notes[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteData {
  final String title;
  final String content;
  final Color color;
  final bool isPinned;
  final String time;

  _NoteData(this.title, this.content, this.color, this.isPinned, this.time);
}

class _NoteCard extends StatelessWidget {
  final _NoteData note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: note.isPinned
              ? note.color.withValues(alpha: 0.4)
              : NimmyColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: note.color,
                ),
              ),
              if (note.isPinned)
                Icon(
                  Icons.push_pin_rounded,
                  color: note.color,
                  size: 16,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            note.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NimmyColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Content preview
          Expanded(
            child: Text(
              note.content,
              style: const TextStyle(
                fontSize: 13,
                color: NimmyColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 5,
              overflow: TextOverflow.fade,
            ),
          ),

          const SizedBox(height: 8),

          // Time
          Text(
            note.time,
            style: const TextStyle(
              fontSize: 11,
              color: NimmyColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
