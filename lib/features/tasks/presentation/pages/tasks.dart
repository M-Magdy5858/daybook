import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/tasks/domain/entities/task.dart';
import 'package:daybook/features/tasks/domain/services/task_query.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:daybook/features/tasks/presentation/widgets/sync_badge.dart';
import 'package:daybook/features/tasks/presentation/widgets/task_card.dart';
import 'package:daybook/features/tasks/presentation/widgets/task_filter_bar.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  static const _sortLabels = {
    TaskSort.manual: 'My order',
    TaskSort.dueDate: 'Due date',
    TaskSort.priority: 'Priority',
    TaskSort.createdAt: 'Newest',
  };

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TasksBloc>();
    final query = context.select((TasksBloc b) => b.state.query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          const SyncBadge(),
          PopupMenuButton<TaskSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            initialValue: query.sort,
            onSelected: (s) => bloc.add(QueryChanged(query.copyWith(sort: s))),
            itemBuilder: (_) => [
              for (final MapEntry(key: sort, value: label)
                  in _sortLabels.entries)
                PopupMenuItem(value: sort, child: Text(label)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New task',
        onPressed: () => context.push(Routes.taskNew),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<TasksBloc, TasksState>(
        listenWhen: (prev, next) =>
            next.failure != null && prev.failure != next.failure,
        listener: (context, state) => context.showSnack(state.failure!.message),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search tasks',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (text) => bloc.add(
                  QueryChanged(bloc.state.query.copyWith(search: text)),
                ),
              ),
            ),
            TaskFilterBar(
              selected: query.filter,
              onChanged: (f) =>
                  bloc.add(QueryChanged(query.copyWith(filter: f))),
            ),
            AppSpacing.gapSm,
            const Expanded(child: _TaskList()),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  Future<void> _refresh(TasksBloc bloc) async {
    bloc.add(const TasksRefreshed());
    await bloc.stream.firstWhere((s) => !s.isRefreshing);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TasksBloc>();
    return BlocBuilder<TasksBloc, TasksState>(
      buildWhen: (prev, next) =>
          prev.status != next.status ||
          prev.tasks != next.tasks ||
          prev.query != next.query,
      builder: (context, state) {
        final now = DateTime.now();
        final tasks = state.visible(now);
        return switch (state.status) {
          TasksStatus.initial || TasksStatus.loading => const AppLoadingState(),
          TasksStatus.failure => AppErrorState(
            message: state.failure?.message ?? 'Could not load tasks',
            onRetry: () => bloc.add(const TasksSubscribed()),
          ),
          TasksStatus.success when tasks.isEmpty => RefreshIndicator(
            onRefresh: () => _refresh(bloc),
            child: ListView(
              children: [
                AppEmptyState(
                  title: state.tasks.isEmpty ? 'No tasks yet' : 'No matches',
                  message: state.tasks.isEmpty
                      ? 'Tap + to add your first task.'
                      : 'Try another filter or search.',
                  icon: Icons.task_alt,
                ),
              ],
            ),
          ),
          TasksStatus.success => RefreshIndicator(
            onRefresh: () => _refresh(bloc),
            child: state.query.canReorder
                ? ReorderableListView.builder(
                    itemCount: tasks.length,
                    onReorderItem: (from, to) =>
                        bloc.add(TasksReordered(from, to)),
                    itemBuilder: (_, i) => _card(tasks[i], now),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _card(tasks[i], now),
                  ),
          ),
        };
      },
    );
  }

  Widget _card(Task task, DateTime now) =>
      TaskCard(key: ValueKey(task.id), task: task, now: now);
}
