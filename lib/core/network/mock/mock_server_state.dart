class MockUser {
  MockUser(this.id, this.name, this.email, this.password);
  final String id, name, email, password;
  Map<String, Object> toJson() => {'id': id, 'name': name, 'email': email};
}

/// The mock server's in-memory "database". It resets when the app restarts.
class MockServerState {
  MockServerState({DateTime? now})
    : tasks = _seedTasks(now ?? DateTime.now()),
      events = _seedEvents(now ?? DateTime.now());

  final users = <MockUser>[
    MockUser('1', 'Demo', 'demo@daybook.dev', 'password123'),
  ];

  /// Tasks as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> tasks;

  /// Calendar events as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> events;

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
}
