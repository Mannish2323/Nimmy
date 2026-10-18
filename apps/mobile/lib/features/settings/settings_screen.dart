import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nimmy_dialog.dart';
import '../../widgets/nimmy_snackbar.dart';
import '../../widgets/status_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final authService = context.watch<AuthService>();
    final isAuthenticated = authService.isAuthenticated;
    final user = authService.currentUser;

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
            borderColor: isAuthenticated
                ? NimmyColors.green.withValues(alpha: 0.35)
                : NimmyColors.purple.withValues(alpha: 0.35),
            onTap: isAuthenticated ? null : () => context.push('/auth'),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: NimmyColors.primaryGradient,
                  ),
                  child: Center(
                    child: Text(
                      isAuthenticated
                          ? (user.displayName?.isNotEmpty == true
                              ? user.displayName![0].toUpperCase()
                              : user.email[0].toUpperCase())
                          : 'N',
                      style: const TextStyle(
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
                        isAuthenticated
                            ? (user.displayName ?? 'Nimmy User')
                            : 'Local profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isAuthenticated
                            ? user.email
                            : 'Tap to sign in & enable cloud sync.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: isAuthenticated ? 'CLOUD' : 'LOCAL',
                  color: isAuthenticated ? NimmyColors.green : NimmyColors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: NimmySpacing.xl),
          if (isAuthenticated) ...[
            _Section(
              title: 'Account',
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out',
                  subtitle: 'Disconnect cloud session and revert to local mode',
                  onTap: () async {
                    final confirm = await NimmyDialog.showConfirmation(
                      context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to sign out? Your local data will be preserved.',
                      confirmLabel: 'Sign Out',
                      isDestructive: false,
                    );
                    if (confirm == true && context.mounted) {
                      await authService.signOut();
                      if (context.mounted) {
                        NimmySnackbar.showSuccess(
                          context,
                          'Signed out. Running in local mode.',
                        );
                      }
                    }
                  },
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete Account',
                  subtitle: 'Permanently remove cloud account & synced data',
                  onTap: () async {
                    final confirm = await NimmyDialog.showConfirmation(
                      context,
                      title: 'Delete Account',
                      message: 'This action is irreversible. All synced memories, reminders, and profile data will be permanently deleted.',
                      confirmLabel: 'Delete Account',
                      isDestructive: true,
                    );
                    if (confirm == true && context.mounted) {
                      await authService.deleteAccount();
                      if (context.mounted) {
                        NimmySnackbar.showSuccess(
                          context,
                          'Account deleted.',
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
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
                    : 'Authenticated sync link is configured',
                badge: controller.isLocalOnly ? 'LOCAL ONLY' : 'CLOUD LINKED',
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
