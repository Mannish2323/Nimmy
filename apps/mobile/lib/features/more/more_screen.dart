import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_MoreItem>[
      const _MoreItem('Reminders', 'Scheduled by you', Icons.alarm_rounded, '/reminders', true),
      const _MoreItem('Activity', 'Tool and audit history', Icons.history_rounded, '/audit', true),
      const _MoreItem('Permissions', 'Microphone and notifications', Icons.shield_outlined, '/permissions', true),
      const _MoreItem('Notes', 'Capture ideas', Icons.note_alt_outlined, '/notes', false),
      const _MoreItem('Recordings', 'Visible, user-started capture', Icons.graphic_eq_rounded, null, false),
      const _MoreItem('Automations', 'Rules that stay under your control', Icons.account_tree_outlined, null, false),
      const _MoreItem('Messages', 'Supported integrations only', Icons.send_outlined, null, false),
      const _MoreItem('App launcher', 'Open supported Android apps', Icons.apps_rounded, null, false),
      const _MoreItem('Analytics', 'Actionable productivity insights', Icons.insights_outlined, null, false),
      const _MoreItem('Settings', 'Privacy, voice and account', Icons.settings_outlined, '/settings', true),
    ];

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              NimmySpacing.xl,
              NimmySpacing.lg,
              NimmySpacing.md,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('More', style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: NimmySpacing.xs),
                  Text(
                    'Powerful tools, kept out of your way.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              0,
              NimmySpacing.lg,
              110,
            ),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: NimmySpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                return GlassCard(
                  onTap: item.route == null ? null : () => context.push(item.route!),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: NimmyColors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(NimmyRadius.sm),
                        ),
                        child: Icon(item.icon, color: NimmyColors.purpleLight),
                      ),
                      const SizedBox(width: NimmySpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (!item.available)
                        const StatusBadge(label: 'COMING SOON')
                      else
                        const Icon(Icons.chevron_right_rounded, color: NimmyColors.textMuted),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem(
    this.title,
    this.subtitle,
    this.icon,
    this.route,
    this.available,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final String? route;
  final bool available;
}
