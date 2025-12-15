/// API Endpoints for Sina'a Admin Panel
class ApiEndpoints {
  ApiEndpoints._();

  // Base URL - change for production
  static const String baseUrl = 'http://localhost:3000/api/v1';
  // static const String baseUrl = 'https://api.sinaa.sa/api/v1'; // Production

  // Admin Auth endpoints
  static const String adminLogin = '/auth/admin/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Dashboard endpoints
  static const String dashboard = '/admin/dashboard';

  // Users management
  static const String users = '/admin/users';
  static String user(int id) => '/admin/users/$id';
  static String userBan(int id) => '/admin/users/$id/ban';

  // Projects management
  static const String projects = '/admin/projects';
  static String project(int id) => '/admin/projects/$id';
  static String projectApprove(int id) => '/admin/projects/$id/approve';
  static String projectReject(int id) => '/admin/projects/$id/reject';
  static String projectDisable(int id) => '/admin/projects/$id/disable';
  static String projectEnable(int id) => '/admin/projects/$id/enable';

  // Products management
  static const String products = '/admin/products';
  static String product(int id) => '/admin/products/$id';
  static String productApprove(int id) => '/admin/products/$id/approve';
  static String productReject(int id) => '/admin/products/$id/reject';
  static String productDisable(int id) => '/admin/products/$id/disable';
  static String productEnable(int id) => '/admin/products/$id/enable';

  // Categories management
  static const String categories = '/admin/categories';
  static String category(int id) => '/admin/categories/$id';
  static String categoryToggle(int id) => '/admin/categories/$id/toggle';
  static const String categoriesReorder = '/admin/categories/reorder';

  // Reviews management
  static const String reviews = '/admin/reviews';
  static String review(int id) => '/admin/reviews/$id';
  static String reviewApprove(int id) => '/admin/reviews/$id/approve';
  static String reviewReject(int id) => '/admin/reviews/$id/reject';

  // Support Tickets management
  static const String tickets = '/admin/support/tickets';
  static String ticket(int id) => '/admin/support/tickets/$id';
  static String ticketStatus(int id) => '/admin/support/tickets/$id/status';
  static String ticketAssign(int id) => '/admin/support/tickets/$id/assign';
  static String ticketResolve(int id) => '/admin/support/tickets/$id/resolve';

  // Settings
  static const String settings = '/admin/settings';

  // Analytics
  static const String analytics = '/admin/analytics';

  // Health check
  static const String health = '/health';
}
