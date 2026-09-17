import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          NimmySpacing.lg,
          NimmySpacing.sm,
          NimmySpacing.lg,
          NimmySpacing.xl,
        ),
        children: [
          GlassCard(
            borderColor: NimmyColors.purple.withValues(alpha: 0.35),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NimmyColors.primaryGradient,
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: NimmySpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Authentication setup is the next foundation step.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const StatusBadge(label: 'LOCAL', color: NimmyColors.amber),
              ],
            ),
          ),
          const SizedBox(height: NimmySpacing.xl),
          _Section(
            title: 'Nimmy',
            children: [
              _SettingsTile(
                icon: Icons.record_voice_over_outlined,
                title: 'Voice',
                subtitle: 'System speech • English (India)',
                badge: 'ACTIVE',
                onTap: () => context.push('/voice'),
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Permissions',
                subtitle: 'Microphone and notification controls',
                onTap: () => context.push('/permissions'),
              ),
              _SettingsTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Memory',
                subtitle: '${controller.memories.length} explicitly saved',
                onTap: () => context.go('/memory'),
              ),
            ],
          ),
          _Section(
            title: 'Data & privacy',
            children: [
              _SettingsTile(
                icon: Icons.cloud_off_outlined,
                title: 'Cloud sync',
                subtitle: controller.isLocalOnly
                    ? 'Not configured • data stays on this device'
                    : 'Connected',
                badge: controller.isLocalOnly ? 'LOCAL ONLY' : 'SYNCED',
              ),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: 'Action history',
                subtitle:
                    '${controller.auditEvents.length} structured audit events',
                onTap: () => context.push('/audit'),
              ),
              const _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric app lock',
                subtitle: 'Not available in this build',
                badge: 'COMING SOON',
              ),
              const _SettingsTile(
                icon: Icons.graphic_eq_rounded,
                title: 'Recording',
                subtitle: 'No recording capability is enabled',
                badge: 'NOT AVAILABLE',
              ),
            ],
          ),
          const _Section(
            title: 'Appearance & app',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: 'Dark theme • reduced motion follows system',
                badge: 'DARK',
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About Nimmy',
                subtitle: 'Version 1.0.0 • MVP foundation',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: NimmySpacing.xs),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: List.generate(children.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const Divider(indent: 58);
                }
                return children[index ~/ 2];
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: NimmyColors.purpleLight),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: badge != null
          ? StatusBadge(label: badge!)
          : onTap != null
          ? const Icon(Icons.chevron_right_rounded)
          : null,
    );
  }
}
