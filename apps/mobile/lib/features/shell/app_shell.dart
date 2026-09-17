import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    ('/home', Icons.home_rounded, Icons.home_outlined, 'Home'),
    ('/tasks', Icons.task_alt_rounded, Icons.task_alt_outlined, 'Tasks'),
    (
      '/calendar',
      Icons.calendar_month_rounded,
      Icons.calendar_month_outlined,
      'Calendar',
    ),
    (
      '/memory',
      Icons.auto_awesome_rounded,
      Icons.auto_awesome_outlined,
      'Memory',
    ),
    ('/more', Icons.grid_view_rounded, Icons.grid_view_outlined, 'More'),
  ];

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((item) => path.startsWith(item.$1));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      extendBody: true,
      body: child,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Semantics(
        button: true,
        label: 'Talk to Nimmy',
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: NimmyColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: NimmyColors.purpleGlow,
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: () => context.push('/voice'),
            icon: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: _NimmyBottomBar(
        selectedIndex: selected,
        onSelect: (index) => context.go(_destinations[index].$1),
      ),
    );
  }
}

class _NimmyBottomBar extends StatelessWidget {
  const _NimmyBottomBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF50C0C14),
        border: Border(top: BorderSide(color: NimmyColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(AppShell._destinations.length + 1, (slot) {
              if (slot == 2) return const SizedBox(width: 70);
              final index = slot < 2 ? slot : slot - 1;
              final item = AppShell._destinations[index];
              final active = selectedIndex == index;
              return Expanded(
                child: InkResponse(
                  onTap: () => onSelect(index),
                  radius: 28,
                  child: Semantics(
                    selected: active,
                    label: item.$4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: NimmyDurations.fast,
                          child: Icon(
                            active ? item.$2 : item.$3,
                            key: ValueKey(active),
                            color: active
                                ? NimmyColors.purpleLight
                                : NimmyColors.textMuted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$4,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? NimmyColors.purpleLight
                                : NimmyColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
