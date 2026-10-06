import 'package:daybook/core/routing/routes.dart';
import 'package:daybook/core/theme/app_spacing.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_cubit.dart';
import 'package:daybook/features/calendar/presentation/cubit/calendar_state.dart';
import 'package:daybook/features/calendar/presentation/views/agenda_view.dart';
import 'package:daybook/features/calendar/presentation/views/day_view.dart';
import 'package:daybook/features/calendar/presentation/views/month_view.dart';
import 'package:daybook/features/calendar/presentation/views/week_view.dart';
import 'package:daybook/shared/extensions/context_extensions.dart';
import 'package:daybook/shared/extensions/date_extensions.dart';
import 'package:daybook/shared/widgets/app_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  String _title(BuildContext context, CalendarState state) {
    final l = MaterialLocalizations.of(context);
    final (from, to) = state.range;
    return switch (state.view) {
      CalendarView.month => l.formatMonthYear(state.focused),
      CalendarView.day => l.formatMediumDate(state.focused),
      CalendarView.week || CalendarView.agenda =>
        '${l.formatShortMonthDay(from)} – '
            '${l.formatShortMonthDay(to.addDays(-1))}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalendarCubit>();
    return BlocConsumer<CalendarCubit, CalendarState>(
      listenWhen: (prev, next) =>
          next.failure != null && prev.failure != next.failure,
      listener: (context, state) => context.showSnack(state.failure!.message),
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(_title(context, state)),
          actions: [
            IconButton(
              tooltip: 'Today',
              icon: const Icon(Icons.today),
              onPressed: cubit.goToToday,
            ),
            IconButton(
              tooltip: 'Previous',
              icon: const Icon(Icons.chevron_left),
              onPressed: cubit.previous,
            ),
            IconButton(
              tooltip: 'Next',
              icon: const Icon(Icons.chevron_right),
              onPressed: cubit.next,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'New event',
          onPressed: () => context.push(Routes.eventNewOn(state.selected)),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: SegmentedButton<CalendarView>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: CalendarView.month,
                    label: Text('Month'),
                  ),
                  ButtonSegment(value: CalendarView.week, label: Text('Week')),
                  ButtonSegment(value: CalendarView.day, label: Text('Day')),
                  ButtonSegment(
                    value: CalendarView.agenda,
                    label: Text('Agenda'),
                  ),
                ],
                selected: {state.view},
                onSelectionChanged: (s) => cubit.changeView(s.first),
              ),
            ),
            Expanded(
              child: state.status == CalendarStatus.loading
                  ? const AppLoadingState()
                  : switch (state.view) {
                      CalendarView.month => MonthView(state: state),
                      CalendarView.week => WeekView(state: state),
                      CalendarView.day => DayView(state: state),
                      CalendarView.agenda => AgendaView(state: state),
                    },
            ),
          ],
        ),
      ),
    );
  }
}
