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
      habits = _seedHabits(now ?? DateTime.now()),
      transactions = _seedTransactions(now ?? DateTime.now());

  final users = <MockUser>[
    MockUser('1', 'Demo', 'demo@daybook.dev', 'password123'),
  ];

  /// Tasks as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> tasks;

  /// Calendar events as JSON maps, keyed by id.
  final Map<String, Map<String, dynamic>> events;

  /// Habits as JSON maps (with their completed days), keyed by id.
  final Map<String, Map<String, dynamic>> habits;

  /// Expense accounts and categories (with budgets), keyed by id.
  final Map<String, Map<String, dynamic>> accounts = _seedAccounts();
  final Map<String, Map<String, dynamic>> categories = _seedCategories();

  /// Money in and out, keyed by id. Amounts are whole piasters.
  final Map<String, Map<String, dynamic>> transactions;

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

  static final _seededAt = DateTime.utc(2026).toIso8601String();

  static Map<String, Map<String, dynamic>> _seedAccounts() => {
    for (final (id, name) in [('acc-cash', 'Cash'), ('acc-card', 'Bank card')])
      id: {
        'id': id,
        'name': name,
        'currency': 'EGP',
        'updatedAt': _seededAt,
        'version': 1,
      },
  };

  // (id, name, icon code point, color, type, monthly budget in EGP)
  static const _categorySeed = [
    ('cat-food', 'Food', 0xe532, 0xFFE65100, 'expense', 4000),
    ('cat-transport', 'Transport', 0xe1d5, 0xFF1E88E5, 'expense', 1500),
    ('cat-shopping', 'Shopping', 0xe59a, 0xFF8E24AA, 'expense', 3000),
    ('cat-bills', 'Bills', 0xe50d, 0xFF546E7A, 'expense', null),
    ('cat-fun', 'Fun', 0xe40d, 0xFF00ACC1, 'expense', 1500),
    ('cat-health', 'Health', 0xe396, 0xFF43A047, 'expense', null),
    ('cat-salary', 'Salary', 0xe482, 0xFF2E7D32, 'income', null),
    ('cat-gifts', 'Gifts', 0xe13e, 0xFFFDD835, 'income', null),
  ];

  static Map<String, Map<String, dynamic>> _seedCategories() => {
    for (final (id, name, icon, color, type, budget) in _categorySeed)
      id: {
        'id': id,
        'name': name,
        'iconCode': icon,
        'colorValue': color,
        'type': type,
        'budgetMinor': budget == null ? null : budget * 100,
        'currency': 'EGP',
        'updatedAt': _seededAt,
        'version': 1,
      },
  };

  /// Six months of history: a salary each month, rent and bills, and about
  /// one smaller expense a day. "Random" but the same every run.
  static Map<String, Map<String, dynamic>> _seedTransactions(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var seed = 20261006;
    int next(int max) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed % max;
    }

    final result = <String, Map<String, dynamic>>{};
    void add(
      DateTime day,
      String category,
      String account,
      int pounds,
      String type, [
      String note = '',
    ]) {
      if (day.isAfter(today)) return;
      final id = 'tx-${result.length + 1}';
      final at = DateTime(day.year, day.month, day.day, 12).toUtc();
      result[id] = {
        'id': id,
        'accountId': account,
        'categoryId': category,
        'amountMinor': pounds * 100 + next(100), // with some piasters
        'currency': 'EGP',
        'type': type,
        'date': at.toIso8601String(),
        'note': note,
        'createdAt': at.toIso8601String(),
        'updatedAt': _seededAt,
        'version': 1,
      };
    }

    const daily = [
      ('cat-food', 80, 400, 'Groceries'),
      ('cat-food', 60, 250, 'Lunch'),
      ('cat-transport', 30, 150, 'Ride'),
      ('cat-shopping', 200, 1200, ''),
      ('cat-fun', 100, 400, 'Cinema'),
      ('cat-health', 100, 600, 'Pharmacy'),
    ];
    for (var m = 5; m >= 0; m--) {
      final month = DateTime(today.year, today.month - m);
      add(month, 'cat-salary', 'acc-card', 25000, 'income', 'Salary');
      add(
        DateTime(month.year, month.month, 3),
        'cat-bills',
        'acc-card',
        6500,
        'expense',
        'Rent',
      );
      add(
        DateTime(month.year, month.month, 10),
        'cat-bills',
        'acc-card',
        350 + next(300),
        'expense',
        'Electricity',
      );
      if (m.isEven) {
        add(
          DateTime(month.year, month.month, 15),
          'cat-gifts',
          'acc-cash',
          500,
          'income',
          'Gift',
        );
      }
      final days = DateTime(month.year, month.month + 1, 0).day;
      for (var d = 1; d <= days; d++) {
        if (next(10) < 3) continue; // some days nothing is spent
        final (cat, min, max, note) = daily[next(daily.length)];
        // Fun and shopping happen less often.
        if ((cat == 'cat-shopping' || cat == 'cat-fun') && next(3) > 0) {
          continue;
        }
        add(
          DateTime(month.year, month.month, d),
          cat,
          next(2) == 0 ? 'acc-cash' : 'acc-card',
          min + next(max - min),
          'expense',
          note,
        );
      }
    }
    return result;
  }
}
