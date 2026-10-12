abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  static const dashboard = '/dashboard';
  static const tasks = '/tasks';
  static const taskNew = '/tasks/new';
  static String taskDetail(String id) => '/tasks/$id';
  static String taskEdit(String id) => '/tasks/$id/edit';

  static const calendar = '/calendar';
  static const eventNew = '/calendar/new';

  /// Full screen above the tabs, so it can be pushed from a task and Back
  /// returns there.
  static const scheduleTask = '/schedule';
  static String eventNewFor({required String taskId, required String title}) =>
      Uri(
        path: scheduleTask,
        queryParameters: {'taskId': taskId, 'title': title},
      ).toString();
  static String eventNewOn(DateTime date) => Uri(
    path: eventNew,
    queryParameters: {'date': date.toIso8601String()},
  ).toString();
  static String eventDetail(String id) => '/calendar/events/$id';

  static const habits = '/habits';
  static const habitNew = '/habits/new';
  static String habitDetail(String id) => '/habits/$id';
  static String habitEdit(String id) => '/habits/$id/edit';

  static const more = '/more';
  static const expenses = '/more/expenses';
  static const expenseNew = '/more/expenses/new';
  static const expenseBudgets = '/more/expenses/budgets';
  static const receiptScan = '/more/expenses/scan';
  static const chat = '/more/chat';
  static String chatRoom(String id) => '/more/chat/$id';
  static const files = '/more/files';
  static const places = '/more/places';
  static const settings = '/more/settings';
  static const gallery = '/more/gallery';

  static const search = '/search';
  static const authRoutes = {login, register};

  static const devTools = '/more/dev';
}
