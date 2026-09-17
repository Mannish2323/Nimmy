import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit/audit_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/memory/memory_screen.dart';
import '../../features/more/more_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/permissions/permission_center_screen.dart';
import '../../features/reminders/reminders_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/voice/voice_screen.dart';

class NimmyRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          _shellRoute('/home', const DashboardScreen()),
          _shellRoute('/tasks', const TasksScreen()),
          _shellRoute('/calendar', const CalendarScreen()),
          _shellRoute('/memory', const MemoryScreen()),
          _shellRoute('/more', const MoreScreen()),
        ],
      ),
      _modalRoute('/voice', const VoiceScreen()),
      _modalRoute('/reminders', const RemindersScreen()),
      _modalRoute('/audit', const AuditScreen()),
      _modalRoute('/permissions', const PermissionCenterScreen()),
      _modalRoute('/notes', const NotesScreen()),
      _modalRoute('/settings', const SettingsScreen()),
    ],
  );

  static GoRoute _shellRoute(String path, Widget child) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => NoTransitionPage(child: child),
    );
  }

  static GoRoute _modalRoute(String path, Widget child) {
    return GoRoute(
      path: path,
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: child,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
