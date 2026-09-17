import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../services/permissions/permission_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class PermissionCenterScreen extends StatefulWidget {
  const PermissionCenterScreen({super.key});

  @override
  State<PermissionCenterScreen> createState() => _PermissionCenterScreenState();
}

class _PermissionCenterScreenState extends State<PermissionCenterScreen> {
  final Map<NimmyPermission, NimmyPermissionStatus> _statuses = {};
  var _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) _load();
  }

  Future<void> _load() async {
    final service = context.read<PermissionService>();
    for (final permission in NimmyPermission.values) {
      try {
        _statuses[permission] = await service.status(permission);
      } catch (_) {
        _statuses[permission] = NimmyPermissionStatus.restricted;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _request(NimmyPermission permission) async {
    final service = context.read<PermissionService>();
    final current = _statuses[permission];
    if (current == NimmyPermissionStatus.permanentlyDenied) {
      await service.openSettings();
      await _load();
      return;
    }
    final value = await service.request(permission);
    if (mounted) setState(() => _statuses[permission] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                NimmySpacing.lg,
                NimmySpacing.sm,
                NimmySpacing.lg,
                NimmySpacing.xl,
              ),
              children: [
                Text(
                  'Permission first. Explanation always.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: NimmySpacing.xs),
                Text(
                  'Nimmy requests access only when a feature needs it. You can keep using text and local data when optional access is denied.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: NimmySpacing.xl),
                _PermissionCard(
                  icon: Icons.mic_none_rounded,
                  title: 'Microphone',
                  description:
                      'Used only after you start a voice command. Nimmy does not use a hidden microphone.',
                  status: _statuses[NimmyPermission.microphone]!,
                  onPressed: () => _request(NimmyPermission.microphone),
                ),
                const SizedBox(height: NimmySpacing.sm),
                _PermissionCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  description:
                      'Used to alert you when a reminder you confirmed becomes due.',
                  status: _statuses[NimmyPermission.notifications]!,
                  onPressed: () => _request(NimmyPermission.notifications),
                ),
                const SizedBox(height: NimmySpacing.xl),
                Text(
                  'Not requested in this build',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: NimmySpacing.sm),
                const _DeferredPermission(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendar',
                  reason: 'External calendar sync is not implemented.',
                ),
                const _DeferredPermission(
                  icon: Icons.contacts_outlined,
                  title: 'Contacts',
                  reason: 'Contact-based commands are not implemented.',
                ),
                const _DeferredPermission(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  reason: 'Location reminders are not implemented.',
                ),
                const _DeferredPermission(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric',
                  reason:
                      'App lock architecture is planned for a later milestone.',
                ),
              ],
            ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final NimmyPermissionStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      NimmyPermissionStatus.allowed => NimmyColors.green,
      NimmyPermissionStatus.denied => NimmyColors.amber,
      NimmyPermissionStatus.restricted ||
      NimmyPermissionStatus.permanentlyDenied => NimmyColors.red,
    };
    final buttonLabel = switch (status) {
      NimmyPermissionStatus.allowed => 'Allowed',
      NimmyPermissionStatus.permanentlyDenied => 'Open settings',
      NimmyPermissionStatus.restricted => 'Restricted',
      NimmyPermissionStatus.denied => 'Allow',
    };
    return GlassCard(
      borderColor: color.withValues(alpha: 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(NimmyRadius.sm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: NimmySpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusBadge(label: status.name.toUpperCase(), color: color),
            ],
          ),
          const SizedBox(height: NimmySpacing.sm),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: NimmySpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  status == NimmyPermissionStatus.allowed ||
                      status == NimmyPermissionStatus.restricted
                  ? null
                  : onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeferredPermission extends StatelessWidget {
  const _DeferredPermission({
    required this.icon,
    required this.title,
    required this.reason,
  });

  final IconData icon;
  final String title;
  final String reason;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NimmySpacing.sm),
      child: GlassCard(
        child: Row(
          children: [
            Icon(icon, color: NimmyColors.textMuted),
            const SizedBox(width: NimmySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(reason, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const StatusBadge(label: 'NOT REQUESTED'),
          ],
        ),
      ),
    );
  }
}
