// 🟣 NIMMY — Dashboard Screen
// ============================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../nimmy_orb/nimmy_orb_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  NimmyOrbState _orbState = NimmyOrbState.idle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello! 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome to Nimmy',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NimmyColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NimmyColors.border),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: NimmyColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Nimmy Orb
            Center(
              child: Column(
                children: [
                  NimmyOrbWidget(
                    size: 160,
                    state: _orbState,
                    onTap: () {
                      setState(() {
                        final states = NimmyOrbState.values;
                        final currentIdx = states.indexOf(_orbState);
                        _orbState = states[(currentIdx + 1) % states.length];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStateLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      color: NimmyColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Stats
            Text(
              'Today\'s Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Tasks',
                    value: '5',
                    color: NimmyColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_rounded,
                    label: 'Events',
                    value: '3',
                    color: NimmyColors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Notes',
                    value: '8',
                    color: NimmyColors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ActivityItem(
              icon: Icons.check_circle_outline,
              title: 'Completed "Design review"',
              time: '2 min ago',
              color: NimmyColors.green,
            ),
            _ActivityItem(
              icon: Icons.mic_rounded,
              title: 'Voice note recorded',
              time: '15 min ago',
              color: NimmyColors.purple,
            ),
            _ActivityItem(
              icon: Icons.psychology_rounded,
              title: 'Memory extracted from conversation',
              time: '1 hour ago',
              color: NimmyColors.cyan,
            ),
            _ActivityItem(
              icon: Icons.auto_awesome,
              title: 'Nimmy suggested 3 tasks',
              time: '2 hours ago',
              color: NimmyColors.amber,
            ),
          ],
        ),
      ),
    );
  }

  String _getStateLabel() {
    switch (_orbState) {
      case NimmyOrbState.idle:
        return 'Tap the orb to change state';
      case NimmyOrbState.listening:
        return '🎤 Listening...';
      case NimmyOrbState.thinking:
        return '🧠 Thinking...';
      case NimmyOrbState.speaking:
        return '💬 Speaking...';
      case NimmyOrbState.recording:
        return '🔴 Recording...';
      case NimmyOrbState.taskComplete:
        return '✅ Task Complete!';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NimmyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: NimmyColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: NimmyColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NimmyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NimmyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NimmyColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
