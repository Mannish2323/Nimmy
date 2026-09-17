import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/reminder.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/status_badge.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  var _filter = _ReminderFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final reminders = _filtered(controller.reminders);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NimmySpacing.sm),
            child: IconButton.filledTonal(
              tooltip: 'Create with Nimmy',
              onPressed: () => context.push('/voice'),
              icon: const Icon(Icons.add_alarm_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: NimmySpacing.lg,
              vertical: NimmySpacing.sm,
            ),
            child: SegmentedButton<_ReminderFilter>(
              segments: const [
                ButtonSegment(
                  value: _ReminderFilter.upcoming,
                  label: Text('Upcoming'),
                ),
                ButtonSegment(
                  value: _ReminderFilter.recurring,
                  label: Text('Recurring'),
                ),
                ButtonSegment(
                  value: _ReminderFilter.history,
                  label: Text('History'),
                ),
              ],
              selected: {_filter},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
          ),
          if (controller.isLocalOnly)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: 'SAVED ON THIS DEVICE',
                  color: NimmyColors.amber,
                  icon: Icons.phone_android_rounded,
                ),
              ),
            ),
          const SizedBox(height: NimmySpacing.sm),
          Expanded(
            child: reminders.isEmpty
                ? NimmyEmptyState(
                    icon: Icons.alarm_off_rounded,
                    title: 'Nothing scheduled',
                    message: _filter == _ReminderFilter.upcoming
                        ? 'Ask Nimmy to create your first reminder.'
                        : 'No reminders match this view.',
                    actionLabel: 'Create with Nimmy',
                    onAction: () => context.push('/voice'),
                  )
                : RefreshIndicator(
                    color: NimmyColors.purple,
                    onRefresh: controller.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        NimmySpacing.lg,
                        0,
                        NimmySpacing.lg,
                        NimmySpacing.xl,
                      ),
                      itemCount: reminders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: NimmySpacing.sm),
                      itemBuilder: (context, index) => _ReminderCard(
                        reminder: reminders[index],
                        onDelete: () => _delete(reminders[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: GlowButton(
        label: 'New reminder',
        icon: Icons.mic_rounded,
        compact: true,
        onPressed: () => context.push('/voice'),
      ),
    );
  }

  List<NimmyReminder> _filtered(List<NimmyReminder> reminders) {
    final now = DateTime.now().toUtc();
    return reminders.where((reminder) {
      return switch (_filter) {
        _ReminderFilter.upcoming =>
          reminder.status == ReminderStatus.pending &&
              reminder.scheduledAt.isAfter(now),
        _ReminderFilter.recurring => reminder.recurrence != null,
        _ReminderFilter.history =>
          reminder.status != ReminderStatus.pending ||
              !reminder.scheduledAt.isAfter(now),
      };
    }).toList();
  }

  Future<void> _delete(NimmyReminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text(
          '“${reminder.title}” will be removed from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: NimmyColors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<NimmyController>().deleteReminder(reminder);
  }
}

enum _ReminderFilter { upcoming, recurring, history }

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.reminder, required this.onDelete});

  final NimmyReminder reminder;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final local = reminder.scheduledAt.toLocal();
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: NimmyColors.amber.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(NimmyRadius.sm),
              border: Border.all(
                color: NimmyColors.amber.withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d').format(local),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  DateFormat('MMM').format(local).toUpperCase(),
                  style: const TextStyle(
                    color: NimmyColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  '${DateFormat('EEEE • h:mm a').format(local)} • ${reminder.timezone}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: NimmySpacing.sm),
                Wrap(
                  spacing: NimmySpacing.xs,
                  runSpacing: NimmySpacing.xs,
                  children: [
                    StatusBadge(
                      label: reminder.status.name.toUpperCase(),
                      color: NimmyColors.green,
                    ),
                    StatusBadge(
                      label: reminder.notificationScheduled
                          ? 'ALERT ON'
                          : 'ALERT UNAVAILABLE',
                      color: reminder.notificationScheduled
                          ? NimmyColors.cyan
                          : NimmyColors.amber,
                    ),
                    if (reminder.recurrence != null)
                      StatusBadge(label: reminder.recurrence!.toUpperCase()),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Reminder actions',
            onSelected: (value) {
              if (value == 'delete') onDelete();
              if (value == 'reschedule') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Rescheduling is not available in this build. Create a replacement with Nimmy.',
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'reschedule',
                child: Text('Reschedule (coming soon)'),
              ),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
