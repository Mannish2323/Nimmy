// 🟣 NIMMY — Settings Screen
// ===========================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),

            // Profile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    NimmyColors.purpleDark.withValues(alpha: 0.3),
                    NimmyColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: NimmyColors.purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [NimmyColors.purpleDark, NimmyColors.purple],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'N',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nimmy User',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: NimmyColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Premium Plan',
                          style: TextStyle(
                            fontSize: 14,
                            color: NimmyColors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: NimmyColors.textMuted),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _SettingsSection(
              title: 'Nimmy AI',
              items: [
                _SettingItem(Icons.record_voice_over_rounded, 'Voice', 'Default', NimmyColors.purple),
                _SettingItem(Icons.psychology_rounded, 'AI Model', 'Gemini Pro', NimmyColors.cyan),
                _SettingItem(Icons.memory_rounded, 'Memory', 'Enabled', NimmyColors.green),
                _SettingItem(Icons.auto_awesome_rounded, 'Smart Suggestions', 'On', NimmyColors.amber),
              ],
            ),

            _SettingsSection(
              title: 'Android Native Core (Kotlin)',
              items: [
                _SettingItem(Icons.android_rounded, 'Foreground Daemon', 'Active', NimmyColors.green),
                _SettingItem(Icons.graphic_eq_rounded, 'AudioRecord Hardware', '16kHz PCM', NimmyColors.purple),
                _SettingItem(Icons.alarm_on_rounded, 'AlarmManager Bridge', 'Enabled', NimmyColors.cyan),
                _SettingItem(Icons.battery_charging_full_rounded, 'Device Telemetry', 'Synced', NimmyColors.amber),
              ],
            ),

            _SettingsSection(
              title: 'Appearance',
              items: [
                _SettingItem(Icons.dark_mode_rounded, 'Theme', 'Dark', NimmyColors.purple),
                _SettingItem(Icons.language_rounded, 'Language', 'English', NimmyColors.cyan),
                _SettingItem(Icons.text_fields_rounded, 'Font Size', 'Medium', NimmyColors.amber),
              ],
            ),

            _SettingsSection(
              title: 'Notifications',
              items: [
                _SettingItem(Icons.notifications_rounded, 'Push Notifications', 'On', NimmyColors.green),
                _SettingItem(Icons.alarm_rounded, 'Reminders', 'On', NimmyColors.amber),
                _SettingItem(Icons.do_not_disturb_rounded, 'Do Not Disturb', 'Off', NimmyColors.red),
              ],
            ),

            _SettingsSection(
              title: 'Data & Privacy',
              items: [
                _SettingItem(Icons.cloud_sync_rounded, 'Sync', 'Supabase', NimmyColors.cyan),
                _SettingItem(Icons.lock_rounded, 'Encryption', 'Enabled', NimmyColors.green),
                _SettingItem(Icons.delete_outline_rounded, 'Clear Data', '', NimmyColors.red),
              ],
            ),

            const SizedBox(height: 24),

            // Version
            Center(
              child: Text(
                'Nimmy v1.0.0 • Built with ❤️',
                style: TextStyle(
                  fontSize: 12,
                  color: NimmyColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: NimmyColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: NimmyColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NimmyColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 15,
                              color: NimmyColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.value.isNotEmpty)
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: NimmyColors.textMuted,
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: NimmyColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 66,
                      color: NimmyColors.border.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  _SettingItem(this.icon, this.label, this.value, this.color);
}
