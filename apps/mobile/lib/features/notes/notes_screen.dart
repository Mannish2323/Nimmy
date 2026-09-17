import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: NimmySpacing.lg),
            child: Center(child: StatusBadge(label: 'COMING SOON')),
          ),
        ],
      ),
      body: const NimmyEmptyState(
        icon: Icons.note_alt_outlined,
        title: 'Notes are not available in this build',
        message:
            'Use “Nimmy, remember this…” for durable, explicit memories while the notes editor is being built.',
      ),
    );
  }
}
