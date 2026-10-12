class MockUser {
  MockUser(this.id, this.name, this.email, this.password);
  final String id, name, email, password;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'email': email};
}

/// The mock server's in-memory "database". It resets when the app restarts.
class MockServerState {
  MockServerState({DateTime? now})
    : tasks = _seedTasks(now ?? DateTime.now()),
      events = _seedEvents(now ?? DateTime.now()),
      habits = _seedHabits(now ?? DateTime.now());

  final users = <MockUser>[
    MockUser('1', 'Demo', 'demo@daybook.dev', 'password123'),
  ];

  /// Tasks as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> tasks;

  /// Calendar events as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> events;

  /// Habits as JSON maps (with their completed days), keyed by id.
  final Map<String, Map<String, dynamic>> habits;

  /// Pretend someone edited [taskId] on another device: bump its version and
  /// change its title. Returns false if there's no such task.
  bool simulateServerEdit(String taskId) {
    final task = tasks[taskId];
    if (task == null) return false;
    task
      ..['title'] = '${task['title']} (edited on server)'
      ..['version'] = (task['version'] as int) + 1
      ..['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    return true;
  }

  static Map<String, Map<String, dynamic>> _seedTasks(DateTime now) {
    // A fixed past timestamp, so local edits always count as newer.
    final seededAt = DateTime.utc(2026).toIso8601String();
    const titles = [
      'Buy milk',
      'Call mom',
      'Pay rent',
      'Book dentist',
      'Water plants',
      'Review PR',
      'Plan trip',
      'Read a chapter',
      'Go for a run',
      'Clean desk',
    ];
    const priorities = ['low', 'medium', 'high'];
    return {
      for (var i = 1; i <= 100; i++)
        'seed-$i': {
          'id': 'seed-$i',
          'title': '${titles[i % titles.length]} #$i',
          'notes': i.isEven ? 'Seeded task' : '',
          'priority': priorities[i % 3],
          'dueDate': i % 4 == 0
              ? null
              : DateTime(
                  now.year,
                  now.month,
                  now.day + (i % 15) - 5,
                  9,
                ).toUtc().toIso8601String(),
          'completedAt': i % 5 == 0 ? seededAt : null,
          'subtasks': <Map<String, dynamic>>[],
          'recurrence': null,
          'position': i,
          'estimatedMinutes': null,
          'createdAt': seededAt,
          'updatedAt': seededAt,
          'version': 1,
        },
    };
  }

  static Map<String, Map<String, dynamic>> _seedEvents(DateTime now) {
    final seededAt = DateTime.utc(2026).toIso8601String();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    String at(DateTime day, int hour, [int minute = 0]) => DateTime(
      day.year,
      day.month,
      day.day,
      hour,
      minute,
    ).toUtc().toIso8601String();
    Map<String, dynamic> event(
      String id,
      String title,
      String start,
      String end, {
      int color = 0xFF1E88E5,
      bool allDay = false,
      Map<String, dynamic>? recurrence,
    }) => {
      'id': id,
      'title': title,
      'start': start,
      'end': end,
      'allDay': allDay,
      'colorValue': color,
      'recurrence': recurrence,
      'excludedDates': <String>[],
      'linkedTaskId': null,
      'createdAt': seededAt,
      'updatedAt': seededAt,
      'version': 1,
    };
    final today = DateTime(now.year, now.month, now.day);
    final holiday = DateTime(now.year, now.month, now.day + 5);
    return {
      for (final e in [
        event(
          'event-standup',
          'Team stand-up',
          at(monday, 10),
          at(monday, 10, 30),
          recurrence: {
            'type': 'weekly',
            'weekdays': [1, 4],
          },
        ),
        event(
          'event-lunch',
          'Lunch with Sara',
          at(today, 13),
          at(today, 14),
          color: 0xFF43A047,
        ),
        event(
          'event-gym',
          'Gym',
          at(monday, 18),
          at(monday, 19),
          color: 0xFFE65100,
          recurrence: {'type': 'everyNDays', 'n': 2},
        ),
        event(
          'event-holiday',
          'Public holiday',
          at(holiday, 0),
          at(holiday.add(const Duration(days: 1)), 0),
          color: 0xFF8E24AA,
          allDay: true,
        ),
      ])
        e['id'] as String: e,
    };
  }

  /// A few habits with ~5 months of history, so streaks and the heatmap have
  /// something to show. "Random" but the same every run.
  static Map<String, Map<String, dynamic>> _seedHabits(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final createdAt = DateTime(today.year, today.month, today.day - 150);
    final seededAt = DateTime.utc(2026).toIso8601String();
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

    Map<String, dynamic> habit(
      String id,
      String name,
      int color,
      List<int> weekdays,
      int donePercent, {
      int? reminderMinutes,
    }) {
      var seed = id.hashCode & 0x7fffffff;
      final done = <String>[];
      // Up to yesterday; today is left for the user to tick.
      for (var i = 150; i >= 1; i--) {
        final day = DateTime(today.year, today.month, today.day - i);
        seed = (seed * 1103515245 + 12345) & 0x7fffffff;
        // The last week is always done, so the streak isn't zero.
        final isDone = i <= 7 || seed % 100 < donePercent;
        if (weekdays.contains(day.weekday) && isDone) done.add(key(day));
      }
      return {
        'id': id,
        'name': name,
        'colorValue': color,
        'weekdays': weekdays,
        'reminderMinutes': reminderMinutes,
        'completions': done,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': seededAt,
        'version': 1,
      };
    }

    const everyDay = [1, 2, 3, 4, 5, 6, 7];
    return {
      for (final h in [
        habit(
          'habit-water',
          'Drink 8 glasses of water',
          0xFF1E88E5,
          everyDay,
          85,
        ),
        habit('habit-read', 'Read 20 pages', 0xFF8E24AA, everyDay, 60),
        habit('habit-gym', 'Gym', 0xFFE65100, [1, 3, 5], 75),
        habit(
          'habit-meditate',
          'Meditate',
          0xFF43A047,
          everyDay,
          50,
          reminderMinutes: 8 * 60,
        ),
      ])
        h['id'] as String: h,
    };
  }
}
