import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/state/nimmy_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/memory.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  final _searchController = TextEditingController();
  MemoryCategory? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NimmyController>();
    final query = _searchController.text.trim().toLowerCase();
    final memories = controller.memories.where((memory) {
      final matchesCategory = _category == null || memory.category == _category;
      final matchesQuery =
          query.isEmpty ||
          memory.content.toLowerCase().contains(query) ||
          memory.category.name.contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              NimmySpacing.xl,
              NimmySpacing.lg,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Memory',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What Nimmy remembers—only with your approval.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Save with Nimmy',
                  onPressed: () => context.push('/voice'),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NimmySpacing.lg,
              NimmySpacing.lg,
              NimmySpacing.lg,
              NimmySpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your memories…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: NimmySpacing.lg),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                const SizedBox(width: NimmySpacing.xs),
                ...[
                  MemoryCategory.preference,
                  MemoryCategory.project,
                  MemoryCategory.goal,
                  MemoryCategory.decision,
                  MemoryCategory.note,
                ].map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: NimmySpacing.xs),
                    child: ChoiceChip(
                      label: Text(_categoryLabel(category)),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NimmySpacing.sm),
          Expanded(
            child: memories.isEmpty
                ? NimmyEmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: controller.memories.isEmpty
                        ? 'Your memory vault is empty'
                        : 'No matching memories',
                    message: controller.memories.isEmpty
                        ? 'Say “Nimmy, remember this…” to save something explicitly.'
                        : 'Try a different search or category.',
                    actionLabel: controller.memories.isEmpty
                        ? 'Talk to Nimmy'
                        : null,
                    onAction: controller.memories.isEmpty
                        ? () => context.push('/voice')
                        : null,
                  )
                : RefreshIndicator(
                    color: NimmyColors.purple,
                    onRefresh: controller.refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        NimmySpacing.lg,
                        0,
                        NimmySpacing.lg,
                        112,
                      ),
                      itemCount: memories.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: NimmySpacing.sm),
                      itemBuilder: (context, index) => _MemoryCard(
                        memory: memories[index],
                        onEdit: () => _edit(memories[index]),
                        onDelete: () => _delete(memories[index]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(NimmyMemory memory) async {
    final editor = TextEditingController(text: memory.content);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit memory'),
        content: TextField(
          controller: editor,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          decoration: const InputDecoration(labelText: 'Memory'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editor.text),
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (value == null || !mounted) return;
    await context.read<NimmyController>().updateMemory(memory, value);
  }

  Future<void> _delete(NimmyMemory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: const Text(
          'Nimmy will no longer be able to retrieve it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NimmyColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<NimmyController>().deleteMemory(memory);
  }

  String _categoryLabel(MemoryCategory category) {
    final value = category.name;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.memory,
    required this.onEdit,
    required this.onDelete,
  });

  final NimmyMemory memory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = switch (memory.category) {
      MemoryCategory.preference => NimmyColors.green,
      MemoryCategory.goal => NimmyColors.amber,
      MemoryCategory.project => NimmyColors.cyan,
      MemoryCategory.person => NimmyColors.pink,
      MemoryCategory.decision => NimmyColors.purpleLight,
      _ => NimmyColors.indigo,
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: memory.categoryLabel.toUpperCase(),
                color: color,
              ),
              const Spacer(),
              PopupMenuButton<String>(
                tooltip: 'Memory actions',
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: NimmySpacing.sm),
          Text(memory.content, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: NimmySpacing.md),
          Row(
            children: [
              Icon(
                memory.source == InteractionSource.voice
                    ? Icons.mic_none_rounded
                    : Icons.keyboard_rounded,
                size: 15,
                color: NimmyColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                memory.source.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                DateFormat('d MMM • h:mm a').format(memory.createdAt.toLocal()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
