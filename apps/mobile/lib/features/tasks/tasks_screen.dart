// 🟣 NIMMY — Tasks Screen
// ========================
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tasks = [
    _TaskItem('Design Nimmy dashboard UI', 'high', true, 'Design'),
    _TaskItem('Set up FastAPI backend', 'high', false, 'Backend'),
    _TaskItem('Write database migrations', 'medium', true, 'Database'),
    _TaskItem('Implement voice recording', 'medium', false, 'Mobile'),
    _TaskItem('Create 3D orb animation', 'low', false, 'Web'),
    _TaskItem('Add push notifications', 'low', false, 'Mobile'),
    _TaskItem('Set up CI/CD pipeline', 'medium', false, 'DevOps'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tasks', style: Theme.of(context).textTheme.headlineLarge),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NimmyColors.purpleDark, NimmyColors.purple],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: NimmyColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NimmyColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: NimmyColors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: NimmyColors.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Done'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Task list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return _TaskCard(task: task);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskItem {
  final String title;
  final String priority;
  final bool isDone;
  final String project;

  _TaskItem(this.title, this.priority, this.isDone, this.project);
}

class _TaskCard extends StatelessWidget {
  final _TaskItem task;

  const _TaskCard({required this.task});

  Color _getPriorityColor() {
    switch (task.priority) {
      case 'high':
        return NimmyColors.red;
      case 'medium':
        return NimmyColors.amber;
      default:
        return NimmyColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NimmyColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.isDone
              ? NimmyColors.green.withValues(alpha: 0.3)
              : NimmyColors.border,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isDone
                  ? NimmyColors.green
                  : Colors.transparent,
              border: Border.all(
                color: task.isDone ? NimmyColors.green : NimmyColors.textMuted,
                width: 2,
              ),
            ),
            child: task.isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: task.isDone
                        ? NimmyColors.textMuted
                        : NimmyColors.textPrimary,
                    decoration:
                        task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPriorityColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getPriorityColor(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NimmyColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.project,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: NimmyColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
