import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/audit_event.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class AuditScreen extends StatelessWidget {
  const AuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: NimmySpacing.lg),
            child: Center(
              child: StatusBadge(
                label: 'AUDIT TRAIL',
                color: NimmyColors.cyan,
                icon: Icons.verified_user_outlined,
              ),
            ),
          ),
        ],
      ),
      body: controller.auditEvents.isEmpty
          ? const NimmyEmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'No actions yet',
              message:
                  'Proposed, confirmed, completed, cancelled and failed actions will appear here.',
            )
          : RefreshIndicator(
              color: NimmyColors.purple,
              onRefresh: controller.refresh,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  NimmySpacing.lg,
                  NimmySpacing.sm,
                  NimmySpacing.lg,
                  NimmySpacing.xl,
                ),
                itemCount: controller.auditEvents.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: NimmySpacing.sm),
                itemBuilder: (context, index) =>
                    _AuditCard(event: controller.auditEvents[index]),
              ),
            ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.event});

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final color = switch (event.status) {
      AuditStatus.executed => NimmyColors.green,
      AuditStatus.failed => NimmyColors.red,
      AuditStatus.cancelled => NimmyColors.textMuted,
      AuditStatus.confirmed => NimmyColors.cyan,
      AuditStatus.proposed => NimmyColors.amber,
    };
    final icon = switch (event.status) {
      AuditStatus.executed => Icons.check_rounded,
      AuditStatus.failed => Icons.error_outline_rounded,
      AuditStatus.cancelled => Icons.close_rounded,
      AuditStatus.confirmed => Icons.shield_outlined,
      AuditStatus.proposed => Icons.pending_actions_rounded,
    };
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(NimmyRadius.sm),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: NimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.toolName.replaceAll('_', ' '),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(
                      label: event.status.name.toUpperCase(),
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${event.source.name} • ${DateFormat('d MMM, h:mm:ss a').format(event.createdAt.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Request ${_shortId(event.requestId)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (event.errorCode != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    event.errorCode!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: NimmyColors.red),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);
}
