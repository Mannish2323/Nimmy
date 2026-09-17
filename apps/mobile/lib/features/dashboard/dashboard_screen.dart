import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/audit_event.dart';
import '../../models/reminder.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../nimmy_orb/nimmy_orb_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final now = DateTime.now();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: NimmyColors.purple,
        onRefresh: controller.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            NimmySpacing.lg,
            NimmySpacing.lg,
            NimmySpacing.lg,
            112,
          ),
          children: [
            _Header(now: now),
            const SizedBox(height: NimmySpacing.xl),
            _OrbHero(controller: controller),
            const SizedBox(height: NimmySpacing.xl),
            _QuickActions(isLocalOnly: controller.isLocalOnly),
            const SizedBox(height: NimmySpacing.xl),
            Text('Today at a glance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NimmySpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    value: '${controller.pendingReminderCount}',
                    label: 'Reminders',
                    color: NimmyColors.amber,
                    icon: Icons.alarm_rounded,
                  ),
                ),
                const SizedBox(width: NimmySpacing.sm),
                Expanded(
                  child: _MetricCard(
                    value: '${controller.memories.length}',
                    label: 'Memories',
                    color: NimmyColors.cyan,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ),
                const SizedBox(width: NimmySpacing.sm),
                Expanded(
                  child: _MetricCard(
                    value: '${controller.auditEvents.length}',
                    label: 'Actions',
                    color: NimmyColors.green,
                    icon: Icons.bolt_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.xl),
            _NextUp(reminder: controller.nextReminder),
            const SizedBox(height: NimmySpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.push('/audit'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.xs),
            if (controller.auditEvents.isEmpty)
              const _NoActivity()
            else
              ...controller.auditEvents.take(3).map(_ActivityTile.new),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final greeting = switch (now.hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEEE, d MMMM').format(now),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _OrbHero extends StatelessWidget {
  const _OrbHero({required this.controller});

  final NimmyController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NimmyRadius.xl),
        gradient: const RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.1,
          colors: [Color(0x334F2B8C), Color(0xEE11111C)],
        ),
        border: Border.all(color: NimmyColors.borderBright),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const StatusBadge(
                label: 'NIMMY READY',
                color: NimmyColors.green,
                icon: Icons.circle,
              ),
              StatusBadge(
                label: controller.isLocalOnly ? 'LOCAL MODE' : 'SYNCED',
                color: controller.isLocalOnly
                    ? NimmyColors.amber
                    : NimmyColors.cyan,
                icon: controller.isLocalOnly
                    ? Icons.cloud_off_outlined
                    : Icons.cloud_done_outlined,
              ),
            ],
          ),
          NimmyOrbWidget(
            size: 190,
            state: controller.orbState,
            onTap: () => context.push('/voice'),
          ),
          Text('Hey, I’m Nimmy.', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: NimmySpacing.xs),
          Text(
            'What should we remember or plan next?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: NimmySpacing.md),
          FilledButton.icon(
            onPressed: () => context.push('/voice'),
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Talk to Nimmy'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isLocalOnly});

  final bool isLocalOnly;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Reminder', Icons.alarm_add_rounded, '/voice', NimmyColors.amber),
      ('Memory', Icons.bookmark_add_outlined, '/voice', NimmyColors.cyan),
      ('View all', Icons.notifications_none_rounded, '/reminders', NimmyColors.purple),
      ('Activity', Icons.history_rounded, '/audit', NimmyColors.green),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NimmySpacing.sm),
        Row(
          children: actions
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item == actions.last ? 0 : NimmySpacing.xs,
                    ),
                    child: InkWell(
                      onTap: () => context.push(item.$3),
                      borderRadius: BorderRadius.circular(NimmyRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: NimmyColors.surface,
                          borderRadius: BorderRadius.circular(NimmyRadius.md),
                          border: Border.all(color: NimmyColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(item.$2, color: item.$4, size: 21),
                            const SizedBox(height: 6),
                            Text(
                              item.$1,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(NimmySpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: NimmySpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  const _NextUp({required this.reminder});

  final NimmyReminder? reminder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next up', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NimmySpacing.sm),
        GlassCard(
          onTap: reminder == null ? () => context.push('/voice') : () => context.push('/reminders'),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: NimmyColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(NimmyRadius.sm),
                ),
                child: const Icon(Icons.alarm_rounded, color: NimmyColors.amber),
              ),
              const SizedBox(width: NimmySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder?.title ?? 'Nothing scheduled',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder == null
                          ? 'Ask Nimmy to create your first reminder.'
                          : DateFormat('EEE, d MMM • h:mm a')
                              .format(reminder!.scheduledAt.toLocal()),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: NimmyColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoActivity extends StatelessWidget {
  const _NoActivity();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Row(
        children: [
          Icon(Icons.auto_awesome_outlined, color: NimmyColors.textMuted),
          SizedBox(width: NimmySpacing.sm),
          Expanded(
            child: Text(
              'No actions yet. Your confirmed Nimmy actions will appear here.',
              style: TextStyle(color: NimmyColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.event);

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    final successful = event.status == AuditStatus.executed;
    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.xs),
      child: GlassCard(
        padding: const EdgeInsets.all(NimmySpacing.sm),
        child: Row(
          children: [
            Icon(
              successful ? Icons.check_circle_outline : Icons.pending_outlined,
              color: successful ? NimmyColors.green : NimmyColors.amber,
              size: 21,
            ),
            const SizedBox(width: NimmySpacing.sm),
            Expanded(
              child: Text(
                event.toolName.replaceAll('_', ' '),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              DateFormat('h:mm a').format(event.createdAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
