// 🟣 NIMMY — Calendar Screen
// ===========================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  final _events = [
    _EventItem('Team standup', '09:00 AM', '09:30 AM', NimmyColors.purple, 'meeting'),
    _EventItem('Design review', '11:00 AM', '12:00 PM', NimmyColors.cyan, 'meeting'),
    _EventItem('Lunch with Alex', '01:00 PM', '02:00 PM', NimmyColors.green, 'personal'),
    _EventItem('Sprint planning', '03:00 PM', '04:00 PM', NimmyColors.amber, 'meeting'),
  ];

  @override
  Widget build(BuildContext context) {
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
                Text('Calendar', style: Theme.of(context).textTheme.headlineLarge),
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

          const SizedBox(height: 20),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  }),
                  icon: const Icon(Icons.chevron_left, color: NimmyColors.textSecondary),
                ),
                Text(
                  _getMonthName(_focusedMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right, color: NimmyColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Week day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((d) => SizedBox(
                        width: 40,
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NimmyColors.textMuted,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Day cells (simple week view)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildWeekRow(),
          ),

          const SizedBox(height: 24),

          // Today's events header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Today\'s Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),

          // Events list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                return _EventCard(event: _events[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;
        final isSelected = day.day == _selectedDay.day;

        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? NimmyColors.purple
                  : isToday
                      ? NimmyColors.surfaceLight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(color: NimmyColors.purple.withValues(alpha: 0.5))
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : NimmyColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _EventItem {
  final String title;
  final String startTime;
  final String endTime;
  final Color color;
  final String type;

  _EventItem(this.title, this.startTime, this.endTime, this.color, this.type);
}

class _EventCard extends StatelessWidget {
  final _EventItem event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NimmyColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NimmyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.startTime} — ${event.endTime}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: NimmyColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              event.type,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: event.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
