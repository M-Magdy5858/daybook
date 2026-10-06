import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:daybook/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// "3 changes waiting" while the outbox has unsent changes.
class SyncBadge extends StatelessWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TasksBloc, TasksState, int>(
      selector: (state) => state.pendingChanges,
      builder: (context, pending) {
        if (pending == 0) {
          return const Tooltip(
            message: 'All changes synced',
            child: Icon(Icons.cloud_done_outlined),
          );
        }
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: Chip(
            avatar: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text(
              pending == 1 ? '1 change waiting' : '$pending changes waiting',
            ),
          ),
        );
      },
    );
  }
}
