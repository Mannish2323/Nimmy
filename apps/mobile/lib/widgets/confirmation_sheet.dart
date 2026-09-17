import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/tool_action.dart';
import 'glow_button.dart';
import 'status_badge.dart';

enum ConfirmationDecision { confirm, edit, cancel }

Future<ConfirmationDecision?> showNimmyConfirmationSheet(
  BuildContext context,
  ToolProposal proposal,
) {
  return showModalBottomSheet<ConfirmationDecision>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ConfirmationSheet(proposal: proposal),
  );
}

class ConfirmationSheet extends StatelessWidget {
  const ConfirmationSheet({super.key, required this.proposal});

  final ToolProposal proposal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        NimmySpacing.lg,
        NimmySpacing.xs,
        NimmySpacing.lg,
        NimmySpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusBadge(
            label: 'CONFIRMATION REQUIRED',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: NimmySpacing.md),
          Text(
            'Here’s what I understood',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: NimmySpacing.xs),
          Text(
            'Nimmy will only perform this action after you confirm.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: NimmySpacing.lg),
          _ProposalPreview(proposal: proposal),
          const SizedBox(height: NimmySpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ConfirmationDecision.cancel,
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: NimmySpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    ConfirmationDecision.edit,
                  ),
                  child: const Text('Edit'),
                ),
              ),
            ],
          ),
          const SizedBox(height: NimmySpacing.sm),
          SizedBox(
            width: double.infinity,
            child: GlowButton(
              label: proposal.intent == NimmyIntent.saveMemory
                  ? 'Save memory'
                  : 'Create reminder',
              icon: proposal.intent == NimmyIntent.saveMemory
                  ? Icons.bookmark_add_rounded
                  : Icons.alarm_add_rounded,
              onPressed: () => Navigator.pop(
                context,
                ConfirmationDecision.confirm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProposalPreview extends StatelessWidget {
  const _ProposalPreview({required this.proposal});

  final ToolProposal proposal;

  @override
  Widget build(BuildContext context) {
    final input = proposal.input;
    final rows = <(String, String)>[];
    if (input is CreateReminderInput) {
      final local = input.scheduledAt.toLocal();
      rows.add(('Action', 'Create reminder'));
      rows.add(('Title', input.title));
      rows.add(('Date', DateFormat('EEE, d MMM yyyy').format(local)));
      rows.add(('Time', DateFormat('h:mm a').format(local)));
      rows.add(('Timezone', input.timezone));
      if (input.recurrence != null) rows.add(('Repeat', input.recurrence!));
    } else if (input is SaveMemoryInput) {
      rows.add(('Action', 'Save memory'));
      rows.add(('Memory', input.content));
      rows.add(('Category', input.category.name));
      rows.add(('Importance', input.importance.name));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NimmySpacing.md),
      decoration: BoxDecoration(
        color: NimmyColors.surfaceRaised,
        borderRadius: BorderRadius.circular(NimmyRadius.lg),
        border: Border.all(color: NimmyColors.borderBright),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
