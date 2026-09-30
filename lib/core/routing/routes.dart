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
  static String eventNewFor({required String taskId, required String title}) =>
      Uri(path: eventNew, queryParameters: {'taskId': taskId, 'title': title}).toString();
  static String eventDetail(String id) => '/calendar/events/$id';

  static const habits = '/habits';
  static String habitDetail(String id) => '/habits/$id';

  static const more = '/more';
  static const expenses = '/more/expenses';
  static const expenseNew = '/more/expenses/new';
  static const receiptScan = '/more/expenses/scan';
  static const chat = '/more/chat';
  static String chatRoom(String id) => '/more/chat/$id';
  static const files = '/more/files';
  static const places = '/more/places';
  static const settings = '/more/settings';

  static const search = '/search';
  static const authRoutes = {login, register};
}