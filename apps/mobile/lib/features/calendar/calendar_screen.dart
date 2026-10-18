import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/calendar_event.dart';
import '../../models/reminder.dart';
import '../../models/task.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nimmy_dialog.dart';
import '../../widgets/nimmy_snackbar.dart';
import '../../widgets/status_badge.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _activeView = 'Agenda';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final selectedDate = controller.selectedCalendarDate;
    final events = controller.eventsForSelectedDate;
    final reminders = controller.remindersForSelectedDate;
    final tasks = controller.tasksForSelectedDate;
    final totalItems = events.length + reminders.length + tasks.length;

    return Scaffold(
      backgroundColor: NimmyColors.voidBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NimmySpacing.lg,
                NimmySpacing.lg,
                NimmySpacing.lg,
                NimmySpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: NimmyColors.purpleLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Calendar & Agenda',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: NimmyColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Schedule event',
                    onPressed: () => _showCreateEventSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 22),
                  ),
                ],
              ),
            ),

            // 2. View Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
              child: Row(
                children: [
                  _ViewModeChip(
                    label: 'Agenda',
                    isSelected: _activeView == 'Agenda',
                    onTap: () => setState(() => _activeView = 'Agenda'),
                  ),
                  const SizedBox(width: NimmySpacing.xs),
                  _ViewModeChip(
                    label: 'Timeline',
                    isSelected: _activeView == 'Timeline',
                    onTap: () => setState(() => _activeView = 'Timeline'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Today',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.selectCalendarDate(DateTime.now()),
                    icon: const Icon(Icons.today_rounded, size: 20, color: NimmyColors.purpleLight),
                  ),
                ],
              ),
            ),

            const SizedBox(height: NimmySpacing.sm),

            // 3. Horizontal Date Strip (14-day window centered around today/selected)
            _HorizontalDateStrip(
              selectedDate: selectedDate,
              onSelectDate: (date) => controller.selectCalendarDate(date),
            ),

            const SizedBox(height: NimmySpacing.md),

            // 4. Selected Date Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
              child: Row(
                children: [
                  Text(
                    _isSameDay(selectedDate, DateTime.now())
                        ? 'Today, ${DateFormat('EEEE, MMM d').format(selectedDate)}'
                        : DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NimmyColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(
                    label: '$totalItems ${totalItems == 1 ? 'ITEM' : 'ITEMS'}',
                    color: totalItems > 0 ? NimmyColors.purpleLight : NimmyColors.textMuted,
                  ),
                ],
              ),
            ),

            const SizedBox(height: NimmySpacing.sm),

            // 5. Unified Agenda List
            Expanded(
              child: totalItems == 0
                  ? NimmyEmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'No agenda for this date',
                      message: 'Nothing is scheduled for ${DateFormat('MMMM d').format(selectedDate)}. Tap “+” to add an event.',
                      actionLabel: 'Schedule Event',
                      onAction: () => _showCreateEventSheet(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        NimmySpacing.lg,
                        NimmySpacing.xs,
                        NimmySpacing.lg,
                        100,
                      ),
                      children: [
                        // Calendar Events Section
                        if (events.isNotEmpty) ...[
                          _AgendaSectionHeader(
                            title: 'EVENTS',
                            count: events.length,
                            icon: Icons.calendar_month_rounded,
                            color: NimmyColors.purple,
                          ),
                          ...events.map(
                            (event) => _CalendarEventCard(
                              event: event,
                              onDelete: () => _deleteEvent(event),
                              onReschedule: () => _rescheduleEvent(event),
                            ),
                          ),
                          const SizedBox(height: NimmySpacing.md),
                        ],

                        // Scheduled Reminders Section
                        if (reminders.isNotEmpty) ...[
                          _AgendaSectionHeader(
                            title: 'REMINDERS',
                            count: reminders.length,
                            icon: Icons.alarm_rounded,
                            color: NimmyColors.amber,
                          ),
                          ...reminders.map(
                            (reminder) => _AgendaReminderCard(reminder: reminder),
                          ),
                          const SizedBox(height: NimmySpacing.md),
                        ],

                        // Due Tasks Section
                        if (tasks.isNotEmpty) ...[
                          _AgendaSectionHeader(
                            title: 'TASKS DUE',
                            count: tasks.length,
                            icon: Icons.check_circle_outline_rounded,
                            color: NimmyColors.green,
                          ),
                          ...tasks.map(
                            (task) => _AgendaTaskCard(
                              task: task,
                              onToggle: () => controller.toggleTaskCompletion(task),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _deleteEvent(NimmyCalendarEvent event) async {
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Delete Event?',
      message: 'Are you sure you want to remove “${event.title}”? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true && mounted) {
      await context.read<NimmyController>().deleteCalendarEvent(event.id);
      if (mounted) {
        NimmySnackbar.showSuccess(context, 'Event deleted.');
      }
    }
  }

  Future<void> _rescheduleEvent(NimmyCalendarEvent event) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: event.startTime,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(event.startTime.toLocal()),
    );
    if (pickedTime == null || !mounted) return;

    final newStart = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await context.read<NimmyController>().rescheduleCalendarEvent(
          event.id,
          newStart,
        );
    if (mounted) {
      NimmySnackbar.showSuccess(
        context,
        'Event rescheduled to ${DateFormat('MMM d, h:mm a').format(newStart)}',
      );
    }
  }

  void _showCreateEventSheet(BuildContext context) {
    final controller = context.read<NimmyController>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider<NimmyController>.value(
        value: controller,
        child: _CreateEventSheet(
          initialDate: controller.selectedCalendarDate,
        ),
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  const _ViewModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(NimmyRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? NimmyColors.purpleDark.withValues(alpha: 0.3)
              : NimmyColors.surfaceSoft,
          borderRadius: BorderRadius.circular(NimmyRadius.sm),
          border: Border.all(
            color: isSelected ? NimmyColors.purpleLight : NimmyColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? NimmyColors.purpleLight : NimmyColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _HorizontalDateStrip extends StatelessWidget {
  const _HorizontalDateStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 14 days: 2 days in the past through 12 days in the future
    final dates = List.generate(15, (index) {
      return DateTime(now.year, now.month, now.day - 2 + index);
    });

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: NimmySpacing.xs),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;

          return InkWell(
            onTap: () => onSelectDate(date),
            borderRadius: BorderRadius.circular(NimmyRadius.md),
            child: AnimatedContainer(
              duration: NimmyDurations.fast,
              width: 54,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? NimmyColors.primaryGradient : null,
                color: isSelected ? null : NimmyColors.surfaceRaised,
                borderRadius: BorderRadius.circular(NimmyRadius.md),
                border: Border.all(
                  color: isSelected
                      ? NimmyColors.purpleLight
                      : isToday
                          ? NimmyColors.purple.withValues(alpha: 0.5)
                          : NimmyColors.border,
                  width: isToday && !isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? NimmyColors.purpleLight
                              : NimmyColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? NimmyColors.purpleLight
                              : NimmyColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? NimmyColors.purpleLight
                              : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AgendaSectionHeader extends StatelessWidget {
  const _AgendaSectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NimmySpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.event,
    required this.onDelete,
    required this.onReschedule,
  });

  final NimmyCalendarEvent event;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context) {
    final startLocal = event.startTime.toLocal();
    final timeStr = event.isAllDay
        ? 'All day'
        : event.endTime != null
            ? '${DateFormat('h:mm a').format(startLocal)} – ${DateFormat('h:mm a').format(event.endTime!.toLocal())}'
            : DateFormat('h:mm a').format(startLocal);

    final typeColor = switch (event.eventType) {
      EventType.meeting => NimmyColors.cyan,
      EventType.deadline => NimmyColors.red,
      EventType.reminder => NimmyColors.amber,
      EventType.aiScheduled => NimmyColors.purpleLight,
      EventType.personal => NimmyColors.purple,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.sm),
      child: GlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: NimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: event.eventType.name.toUpperCase(),
                        color: typeColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: NimmyColors.textPrimary,
                    ),
                  ),
                  if (event.description != null && event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: NimmyColors.textSecondary,
                      ),
                    ),
                  ],
                  if (event.location != null && event.location!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: NimmyColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          event.location!,
                          style: const TextStyle(fontSize: 11, color: NimmyColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Event actions',
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: NimmyColors.textMuted),
              onSelected: (value) {
                if (value == 'reschedule') onReschedule();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'reschedule',
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Reschedule'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: NimmyColors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: NimmyColors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaReminderCard extends StatelessWidget {
  const _AgendaReminderCard({required this.reminder});

  final NimmyReminder reminder;

  @override
  Widget build(BuildContext context) {
    final local = reminder.scheduledAt.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.sm),
      child: GlassCard(
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: NimmyColors.amber, size: 20),
            const SizedBox(width: NimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NimmyColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(local),
                    style: const TextStyle(fontSize: 12, color: NimmyColors.amber),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: reminder.notificationScheduled ? 'ALERT ON' : 'SCHEDULED',
              color: NimmyColors.amber,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaTaskCard extends StatelessWidget {
  const _AgendaTaskCard({required this.task, required this.onToggle});

  final NimmyTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.sm),
      child: GlassCard(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                task.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: task.isCompleted ? NimmyColors.green : NimmyColors.purpleLight,
                size: 22,
              ),
              onPressed: onToggle,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? NimmyColors.textMuted : NimmyColors.textPrimary,
                ),
              ),
            ),
            StatusBadge(
              label: task.priority.name.toUpperCase(),
              color: task.priority == TaskPriority.urgent
                  ? NimmyColors.red
                  : task.priority == TaskPriority.high
                      ? NimmyColors.amber
                      : NimmyColors.purpleLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  late DateTime _startDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  bool _isAllDay = false;
  EventType _eventType = EventType.personal;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        NimmySpacing.lg,
        NimmySpacing.lg,
        NimmySpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + NimmySpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: NimmyColors.surfaceRaised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(NimmyRadius.xl)),
        border: Border(top: BorderSide(color: NimmyColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_rounded, color: NimmyColors.purpleLight, size: 24),
                const SizedBox(width: NimmySpacing.sm),
                Text(
                  'Schedule Event',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: NimmyColors.textPrimary,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded, color: NimmyColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.md),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: NimmyColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Event Title',
                hintText: 'e.g. Design Sprint Sync',
              ),
            ),
            const SizedBox(height: NimmySpacing.sm),
            TextField(
              controller: _descController,
              style: const TextStyle(color: NimmyColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Notes, agenda, link...',
              ),
            ),
            const SizedBox(height: NimmySpacing.sm),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: NimmyColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Location / Platform (optional)',
                hintText: 'Google Meet, Room 402...',
              ),
            ),
            const SizedBox(height: NimmySpacing.md),
            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                ),
                const SizedBox(width: NimmySpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text(_startTime.format(context)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) {
                        setState(() {
                          _startTime = picked;
                          _endTime = TimeOfDay(
                            hour: (picked.hour + 1) % 24,
                            minute: picked.minute,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: NimmySpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(_endTime.format(context)),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.sm),
            Row(
              children: [
                const Text(
                  'All-day event',
                  style: TextStyle(fontSize: 14, color: NimmyColors.textPrimary),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _isAllDay,
                  onChanged: (val) => setState(() => _isAllDay = val),
                  activeTrackColor: NimmyColors.cyan,
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.sm),
            // Event Type Chips
            Wrap(
              spacing: NimmySpacing.xs,
              children: EventType.values.map((type) {
                final isSel = _eventType == type;
                return ChoiceChip(
                  label: Text(type.name.toUpperCase()),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _eventType = type);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: NimmySpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveEvent,
                child: const Text('Schedule Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      NimmySnackbar.showError(context, 'Please enter an event title.');
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    await context.read<NimmyController>().createCalendarEvent(
          title: title,
          startTime: startDateTime,
          endTime: endDateTime,
          isAllDay: _isAllDay,
          eventType: _eventType,
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          location: _locationController.text.trim().isNotEmpty
              ? _locationController.text.trim()
              : null,
        );

    if (mounted) {
      Navigator.pop(context);
      NimmySnackbar.showSuccess(context, 'Event scheduled for ${DateFormat('MMM d, h:mm a').format(startDateTime)}');
    }
  }
}
