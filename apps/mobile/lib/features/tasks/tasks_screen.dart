import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

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
                  child: Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const StatusBadge(label: 'COMING SOON'),
              ],
            ),
          ),
          const Expanded(
            child: NimmyEmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Task management is not available yet',
              message:
                  'This build focuses on the verified reminder and memory flows. Tasks will be connected in a later milestone.',
            ),
          ),
        ],
      ),
    );
  }
}
