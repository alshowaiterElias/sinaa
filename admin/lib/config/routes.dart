import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/users/screens/users_list_screen.dart';
import '../features/projects/screens/projects_screen.dart';
import '../features/projects/screens/project_detail_screen.dart';
import '../features/products/screens/products_list_screen.dart';
import '../features/products/screens/product_detail_screen.dart';
import '../features/categories/screens/categories_screen.dart';
import '../features/reviews/screens/reviews_screen.dart';
import '../features/tickets/screens/tickets_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../layouts/admin_layout.dart';

// Route names
class AdminRoutes {
  AdminRoutes._();

  static const String login = '/login';
  static const String dashboard = '/';
  static const String users = '/users';
  static const String userDetail = '/users/:id';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String products = '/products';
  static const String productDetail = '/products/:id';
  static const String categories = '/categories';
  static const String reviews = '/reviews';
  static const String tickets = '/tickets'; // Support tickets route
  static const String ticketDetail = '/tickets/:id';
  static const String settings = '/settings';
}

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthStateProvider);

  return GoRouter(
    initialLocation: AdminRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoginPage = state.matchedLocation == AdminRoutes.login;
      final isInitialized = authState.isInitialized;

      // Don't redirect until initialized
      if (!isInitialized) {
        return null;
      }

      // Redirect to login if not authenticated
      if (!isLoggedIn && !isLoginPage) {
        return AdminRoutes.login;
      }

      // Redirect to dashboard if authenticated and on login page
      if (isLoggedIn && isLoginPage) {
        return AdminRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // Login route (outside admin layout)
      GoRoute(
        path: AdminRoutes.login,
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Admin routes with layout
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
            path: AdminRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.users,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UsersListScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.projects,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return NoTransitionPage(
                    child: ProjectDetailScreen(projectId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.products,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductsListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return NoTransitionPage(
                    child: ProductDetailScreen(productId: id),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: AdminRoutes.categories,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.reviews,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ReviewsScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.tickets,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TicketsScreen(),
            ),
          ),
          GoRoute(
            path: AdminRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'الصفحة غير موجودة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${state.uri}'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AdminRoutes.dashboard),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
});
