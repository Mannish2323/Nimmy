// 🟣 NIMMY — Memory Screen
// =========================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MemoryScreen extends StatelessWidget {
  const MemoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memories = [
      _MemoryItem('Prefers dark mode in all apps', 'preference', 9, '2 days ago'),
      _MemoryItem('Works as a software developer', 'fact', 10, '1 week ago'),
      _MemoryItem('Has a meeting every Tuesday at 10 AM', 'habit', 7, '3 days ago'),
      _MemoryItem('Interested in AI and machine learning', 'insight', 8, '5 days ago'),
      _MemoryItem('Best friend is Alex — often mentioned', 'relationship', 6, '1 week ago'),
      _MemoryItem('Prefers concise summaries over details', 'preference', 8, '4 days ago'),
      _MemoryItem('Birthday is March 15', 'fact', 9, '2 weeks ago'),
      _MemoryItem('Usually exercises in the morning', 'habit', 5, '1 week ago'),
    ];

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memory', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text(
                  'What Nimmy remembers about you',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Memory stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _MemoryStatChip('${memories.length}', 'Total', NimmyColors.purple),
                const SizedBox(width: 10),
                _MemoryStatChip('3', 'Facts', NimmyColors.cyan),
                const SizedBox(width: 10),
                _MemoryStatChip('2', 'Habits', NimmyColors.amber),
                const SizedBox(width: 10),
                _MemoryStatChip('2', 'Prefs', NimmyColors.green),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Memory list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                return _MemoryCard(memory: memories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryStatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MemoryStatChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryItem {
  final String content;
  final String type;
  final int importance;
  final String time;

  _MemoryItem(this.content, this.type, this.importance, this.time);
}

class _MemoryCard extends StatelessWidget {
  final _MemoryItem memory;

  const _MemoryCard({required this.memory});

  IconData _getIcon() {
    switch (memory.type) {
      case 'fact': return Icons.info_outline_rounded;
      case 'preference': return Icons.tune_rounded;
      case 'habit': return Icons.repeat_rounded;
      case 'relationship': return Icons.people_outline_rounded;
      case 'insight': return Icons.lightbulb_outline_rounded;
      default: return Icons.memory_rounded;
    }
  }

  Color _getColor() {
    switch (memory.type) {
      case 'fact': return NimmyColors.cyan;
      case 'preference': return NimmyColors.green;
      case 'habit': return NimmyColors.amber;
      case 'relationship': return NimmyColors.pink;
      case 'insight': return NimmyColors.purple;
      default: return NimmyColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NimmyColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getIcon(), color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NimmyColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        memory.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Importance dots
                    Row(
                      children: List.generate(5, (i) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < (memory.importance / 2).ceil()
                                ? color
                                : NimmyColors.surfaceLight,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    Text(
                      memory.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: NimmyColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
