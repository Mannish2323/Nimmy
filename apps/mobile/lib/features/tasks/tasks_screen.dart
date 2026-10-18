import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/goal.dart';
import '../../models/habit.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glow_button.dart';
import '../../widgets/nimmy_dialog.dart';
import '../../widgets/nimmy_snackbar.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskStatus? _selectedStatusFilter;
  String? _selectedProjectFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              NimmySpacing.lg,
              NimmySpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Productivity',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${controller.pendingTaskCount} active tasks • ${controller.projects.length} projects',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NimmyColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _openCreationFlow(context, controller),
                  tooltip: 'Create new item',
                ),
              ],
            ),
          ),
          const SizedBox(height: NimmySpacing.md),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
            indicatorColor: NimmyColors.purple,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: NimmyColors.textMuted,
            tabs: [
              Tab(
                child: Row(
                  children: [
                    const Text('Tasks'),
                    if (controller.pendingTaskCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: NimmyColors.purple.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${controller.pendingTaskCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(text: 'Projects (${controller.projects.length})'),
              Tab(text: 'Goals (${controller.goals.length})'),
              Tab(text: 'Habits (${controller.habits.length})'),
            ],
          ),
          const Divider(height: 1, color: NimmyColors.border),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(context, controller),
                _buildProjectsTab(context, controller),
                _buildGoalsTab(context, controller),
                _buildHabitsTab(context, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreationFlow(BuildContext context, NimmyController controller) {
    switch (_tabController.index) {
      case 0:
        _showCreateTaskSheet(context, controller);
        break;
      case 1:
        _showCreateProjectDialog(context, controller);
        break;
      case 2:
        _showCreateGoalDialog(context, controller);
        break;
      case 3:
        _showCreateHabitDialog(context, controller);
        break;
    }
  }

  // ==========================================
  // TASKS TAB
  // ==========================================

  Widget _buildTasksTab(BuildContext context, NimmyController controller) {
    var filteredTasks = controller.tasks;
    if (_selectedStatusFilter != null) {
      filteredTasks = filteredTasks
          .where((t) => t.status == _selectedStatusFilter)
          .toList();
    }
    if (_selectedProjectFilter != null) {
      filteredTasks = filteredTasks
          .where((t) => t.projectId == _selectedProjectFilter)
          .toList();
    }

    return Column(
      children: [
        _buildTaskFilterBar(controller),
        Expanded(
          child: filteredTasks.isEmpty
              ? NimmyEmptyState(
                  icon: Icons.task_alt_rounded,
                  title: 'No tasks found',
                  message: controller.tasks.isEmpty
                      ? 'Add your first task using the + button or ask Nimmy.'
                      : 'No tasks match the active filters.',
                  actionLabel: 'Create Task',
                  onAction: () => _showCreateTaskSheet(context, controller),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(NimmySpacing.lg),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: NimmySpacing.sm),
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _TaskCard(
                      task: task,
                      project: task.projectId != null
                          ? controller.projects
                              .where((p) => p.id == task.projectId)
                              .firstOrNull
                          : null,
                      onToggle: () => controller.toggleTaskCompletion(task),
                      onDelete: () => _confirmDeleteTask(context, controller, task),
                      onEdit: () => _showEditTaskDialog(context, controller, task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskFilterBar(NimmyController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: NimmySpacing.lg,
        vertical: NimmySpacing.sm,
      ),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedStatusFilter == null && _selectedProjectFilter == null,
            onSelected: (_) {
              setState(() {
                _selectedStatusFilter = null;
                _selectedProjectFilter = null;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('To Do'),
            selected: _selectedStatusFilter == TaskStatus.todo,
            onSelected: (val) {
              setState(() {
                _selectedStatusFilter = val ? TaskStatus.todo : null;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Done'),
            selected: _selectedStatusFilter == TaskStatus.done,
            onSelected: (val) {
              setState(() {
                _selectedStatusFilter = val ? TaskStatus.done : null;
              });
            },
          ),
          if (controller.projects.isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(height: 20, width: 1, color: NimmyColors.border),
            const SizedBox(width: 12),
            ...controller.projects.map((proj) {
              final isSelected = _selectedProjectFilter == proj.id;
              final color = _parseColor(proj.color);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: color,
                    radius: 5,
                  ),
                  label: Text(proj.title),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedProjectFilter = val ? proj.id : null;
                    });
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // PROJECTS TAB
  // ==========================================

  Widget _buildProjectsTab(BuildContext context, NimmyController controller) {
    final projects = controller.projects;
    if (projects.isEmpty) {
      return NimmyEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No projects yet',
        message: 'Group related tasks into organized projects.',
        actionLabel: 'New Project',
        onAction: () => _showCreateProjectDialog(context, controller),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(NimmySpacing.lg),
      itemCount: projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: NimmySpacing.md),
      itemBuilder: (context, index) {
        final project = projects[index];
        final projectTasks =
            controller.tasks.where((t) => t.projectId == project.id).toList();
        final completedCount =
            projectTasks.where((t) => t.isCompleted).length;
        final progress = projectTasks.isEmpty
            ? 0.0
            : completedCount / projectTasks.length;

        final projectColor = _parseColor(project.color);

        return GlassCard(
          borderColor: projectColor.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: projectColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: projectColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: NimmyColors.textMuted,
                    onPressed: () => _confirmDeleteProject(context, controller, project),
                  ),
                ],
              ),
              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  project.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NimmyColors.textMuted,
                      ),
                ),
              ],
              const SizedBox(height: NimmySpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${projectTasks.length} tasks • $completedCount done',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NimmyColors.textMuted,
                        ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: projectColor,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: NimmyColors.surfaceSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(projectColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // GOALS TAB
  // ==========================================

  Widget _buildGoalsTab(BuildContext context, NimmyController controller) {
    final goals = controller.goals;
    if (goals.isEmpty) {
      return NimmyEmptyState(
        icon: Icons.flag_rounded,
        title: 'No active goals',
        message: 'Define strategic objectives and track milestones.',
        actionLabel: 'New Goal',
        onAction: () => _showCreateGoalDialog(context, controller),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(NimmySpacing.lg),
      itemCount: goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: NimmySpacing.md),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: goal.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                        if (goal.description != null &&
                            goal.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            goal.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: NimmyColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: NimmyColors.textMuted,
                    onPressed: () => _confirmDeleteGoal(context, controller, goal),
                  ),
                ],
              ),
              const SizedBox(height: NimmySpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    goal.targetDate != null
                        ? 'Target: ${DateFormat.yMMMd().format(goal.targetDate!.toLocal())}'
                        : 'Ongoing goal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NimmyColors.textMuted,
                        ),
                  ),
                  Text(
                    '${(goal.progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: goal.isCompleted
                              ? NimmyColors.green
                              : NimmyColors.cyan,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  trackHeight: 5,
                  activeTrackColor: goal.isCompleted
                      ? NimmyColors.green
                      : NimmyColors.cyan,
                  inactiveTrackColor: NimmyColors.surfaceSoft,
                ),
                child: Slider(
                  value: goal.progress,
                  onChanged: (val) {
                    controller.updateGoalProgress(goal, val);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HABITS TAB
  // ==========================================

  Widget _buildHabitsTab(BuildContext context, NimmyController controller) {
    final habits = controller.habits;
    if (habits.isEmpty) {
      return NimmyEmptyState(
        icon: Icons.repeat_rounded,
        title: 'No habits tracked',
        message: 'Build positive daily routines and maintain your streaks.',
        actionLabel: 'New Habit',
        onAction: () => _showCreateHabitDialog(context, controller),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(NimmySpacing.lg),
      itemCount: habits.length,
      separatorBuilder: (_, __) => const SizedBox(height: NimmySpacing.sm),
      itemBuilder: (context, index) {
        final habit = habits[index];
        final doneToday = habit.isCompletedToday;

        return GlassCard(
          borderColor: doneToday
              ? NimmyColors.green.withValues(alpha: 0.4)
              : null,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  doneToday ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: doneToday ? NimmyColors.green : NimmyColors.textMuted,
                  size: 26,
                ),
                onPressed: () => controller.toggleHabitToday(habit),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${habit.frequency.toUpperCase()} • Best streak: ${habit.bestStreak}d',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NimmyColors.textMuted,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: habit.streakCount > 0
                      ? Colors.orange.withValues(alpha: 0.2)
                      : NimmyColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: habit.streakCount > 0
                        ? Colors.orange.withValues(alpha: 0.4)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  '🔥 ${habit.streakCount}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: habit.streakCount > 0 ? Colors.orangeAccent : NimmyColors.textMuted,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: NimmyColors.textMuted,
                onPressed: () => _confirmDeleteHabit(context, controller, habit),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // DIALOGS & SHEETS
  // ==========================================

  void _showCreateTaskSheet(BuildContext context, NimmyController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateTaskSheet(controller: controller),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    NimmyController controller,
    NimmyTask task,
  ) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');
    var priority = task.priority;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => NimmyDialog(
          title: 'Edit Task',
          confirmLabel: 'Save',
          onConfirm: () {
            if (titleController.text.trim().isEmpty) return;
            controller.updateTask(task.copyWith(
              title: titleController.text.trim(),
              description: descController.text.trim(),
              priority: priority,
            ));
            Navigator.of(dialogCtx).pop();
            NimmySnackbar.show(context, message: 'Task updated', type: SnackbarType.success);
          },
          onCancel: () => Navigator.of(dialogCtx).pop(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Priority:', style: TextStyle(color: NimmyColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              SegmentedButton<TaskPriority>(
                segments: const [
                  ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                  ButtonSegment(value: TaskPriority.medium, label: Text('Med')),
                  ButtonSegment(value: TaskPriority.high, label: Text('High')),
                  ButtonSegment(value: TaskPriority.urgent, label: Text('Urgent')),
                ],
                selected: {priority},
                onSelectionChanged: (set) => setDialogState(() => priority = set.first),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTask(
    BuildContext context,
    NimmyController controller,
    NimmyTask task,
  ) async {
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Delete Task',
      message: 'Are you sure you want to delete "${task.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await controller.deleteTask(task.id);
      if (context.mounted) {
        NimmySnackbar.show(context, message: 'Task deleted', type: SnackbarType.info);
      }
    }
  }

  void _confirmDeleteProject(
    BuildContext context,
    NimmyController controller,
    NimmyProject project,
  ) async {
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Delete Project',
      message: 'Delete project "${project.title}"? Tasks linked to this project will remain intact.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await controller.deleteProject(project.id);
      if (context.mounted) {
        NimmySnackbar.show(context, message: 'Project deleted', type: SnackbarType.info);
      }
    }
  }

  void _confirmDeleteGoal(
    BuildContext context,
    NimmyController controller,
    NimmyGoal goal,
  ) async {
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Delete Goal',
      message: 'Delete goal "${goal.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await controller.deleteGoal(goal.id);
      if (context.mounted) {
        NimmySnackbar.show(context, message: 'Goal deleted', type: SnackbarType.info);
      }
    }
  }

  void _confirmDeleteHabit(
    BuildContext context,
    NimmyController controller,
    NimmyHabit habit,
  ) async {
    final confirmed = await NimmyDialog.showConfirmation(
      context,
      title: 'Delete Habit',
      message: 'Delete habit "${habit.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      await controller.deleteHabit(habit.id);
      if (context.mounted) {
        NimmySnackbar.show(context, message: 'Habit deleted', type: SnackbarType.info);
      }
    }
  }

  void _showCreateProjectDialog(
    BuildContext context,
    NimmyController controller,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    var selectedColor = '#A855F7';
    final colors = ['#A855F7', '#38BDF8', '#34D399', '#F59E0B', '#EF4444', '#EC4899'];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => NimmyDialog(
          title: 'New Project',
          confirmLabel: 'Create',
          onConfirm: () {
            if (titleController.text.trim().isEmpty) return;
            controller.createProject(
              title: titleController.text.trim(),
              description: descController.text.trim(),
              color: selectedColor,
            );
            Navigator.of(dialogCtx).pop();
            NimmySnackbar.show(context, message: 'Project created', type: SnackbarType.success);
          },
          onCancel: () => Navigator.of(dialogCtx).pop(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 16),
              const Text('Accent Color:', style: TextStyle(color: NimmyColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((c) {
                  final color = _parseColor(c);
                  final isSelected = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGoalDialog(
    BuildContext context,
    NimmyController controller,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => NimmyDialog(
        title: 'New Goal',
        confirmLabel: 'Create',
        onConfirm: () {
          if (titleController.text.trim().isEmpty) return;
          controller.createGoal(
            title: titleController.text.trim(),
            description: descController.text.trim(),
          );
          Navigator.of(dialogCtx).pop();
          NimmySnackbar.show(context, message: 'Goal created', type: SnackbarType.success);
        },
        onCancel: () => Navigator.of(dialogCtx).pop(),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateHabitDialog(
    BuildContext context,
    NimmyController controller,
  ) {
    final titleController = TextEditingController();
    var frequency = 'daily';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => NimmyDialog(
          title: 'New Habit',
          confirmLabel: 'Create',
          onConfirm: () {
            if (titleController.text.trim().isEmpty) return;
            controller.createHabit(
              title: titleController.text.trim(),
              frequency: frequency,
            );
            Navigator.of(dialogCtx).pop();
            NimmySnackbar.show(context, message: 'Habit created', type: SnackbarType.success);
          },
          onCancel: () => Navigator.of(dialogCtx).pop(),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Habit Name (e.g. Read 20 mins)'),
              ),
              const SizedBox(height: 16),
              const Text('Frequency:', style: TextStyle(color: NimmyColors.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'daily', label: Text('Daily')),
                  ButtonSegment(value: 'weekdays', label: Text('Weekdays')),
                  ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ],
                selected: {frequency},
                onSelectionChanged: (set) => setDialogState(() => frequency = set.first),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return NimmyColors.purple;
    }
  }
}

// ==========================================
// TASK ITEM CARD
// ==========================================

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    this.project,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  final NimmyTask task;
  final NimmyProject? project;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (task.priority) {
      TaskPriority.urgent => Colors.redAccent,
      TaskPriority.high => Colors.orangeAccent,
      TaskPriority.medium => NimmyColors.cyan,
      TaskPriority.low => NimmyColors.textMuted,
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: NimmySpacing.md,
        vertical: NimmySpacing.sm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              task.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: task.isCompleted ? NimmyColors.green : NimmyColors.textMuted,
              size: 24,
            ),
            onPressed: onToggle,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration:
                            task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? NimmyColors.textMuted : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NimmyColors.textMuted,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        task.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    if (project != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: NimmyColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project!.title,
                          style: const TextStyle(
                            fontSize: 10,
                            color: NimmyColors.textMuted,
                          ),
                        ),
                      ),
                    if (task.dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: task.isOverdue
                                ? Colors.redAccent
                                : NimmyColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat.MMMd().format(task.dueDate!.toLocal()),
                            style: TextStyle(
                              fontSize: 10,
                              color: task.isOverdue
                                  ? Colors.redAccent
                                  : NimmyColors.textMuted,
                              fontWeight: task.isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: NimmyColors.textMuted),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// CREATE TASK BOTTOM SHEET
// ==========================================

class _CreateTaskSheet extends StatefulWidget {
  const _CreateTaskSheet({required this.controller});

  final NimmyController controller;

  @override
  State<_CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends State<_CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  String? _selectedProjectId;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        NimmySpacing.lg,
        NimmySpacing.lg,
        NimmySpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + NimmySpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161524),
        borderRadius: BorderRadius.vertical(top: Radius.circular(NimmyRadius.xl)),
        border: Border(top: BorderSide(color: NimmyColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Task',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: NimmySpacing.md),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'What needs to be done?',
                labelText: 'Task Title',
              ),
            ),
            const SizedBox(height: NimmySpacing.sm),
            TextField(
              controller: _descController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Add additional details or notes',
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: NimmySpacing.md),
            const Text(
              'Priority',
              style: TextStyle(color: NimmyColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                ButtonSegment(value: TaskPriority.medium, label: Text('Med')),
                ButtonSegment(value: TaskPriority.high, label: Text('High')),
                ButtonSegment(value: TaskPriority.urgent, label: Text('Urgent')),
              ],
              selected: {_priority},
              onSelectionChanged: (set) => setState(() => _priority = set.first),
            ),
            if (widget.controller.projects.isNotEmpty) ...[
              const SizedBox(height: NimmySpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: _selectedProjectId,
                decoration: const InputDecoration(labelText: 'Project'),
                dropdownColor: const Color(0xFF1E1D30),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Project')),
                  ...widget.controller.projects.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.title),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedProjectId = val),
              ),
            ],
            const SizedBox(height: NimmySpacing.md),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dueDate == null
                      ? 'Set Due Date'
                      : DateFormat.MMMd().format(_dueDate!.toLocal())),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        _dueDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          18,
                          0,
                        );
                      });
                    }
                  },
                ),
                if (_dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _dueDate = null),
                  ),
              ],
            ),
            const SizedBox(height: NimmySpacing.lg),
            GlowButton(
              label: 'Add Task',
              icon: Icons.check,
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;

                widget.controller.createTask(
                  title: title,
                  description: _descController.text.trim(),
                  priority: _priority,
                  projectId: _selectedProjectId,
                  dueDate: _dueDate,
                );
                Navigator.pop(context);
                NimmySnackbar.show(context, message: 'Task created', type: SnackbarType.success);
              },
            ),
          ],
        ),
      ),
    );
  }
}
