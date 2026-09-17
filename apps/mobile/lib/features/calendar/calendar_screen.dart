import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              NimmySpacing.xl,
              NimmySpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Calendar', style: Theme.of(context).textTheme.headlineLarge),
                ),
                const StatusBadge(label: 'COMING SOON'),
              ],
            ),
          ),
          const Expanded(
            child: NimmyEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Calendar integration is not connected',
              message:
                  'Nimmy will add day, week and month planning after the core action pipeline is verified.',
            ),
          ),
        ],
      ),
    );
  }
}
