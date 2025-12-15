import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/project_owner_register_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/categories/screens/all_categories_screen.dart';
import '../features/projects/screens/project_detail_screen.dart';
import '../features/projects/screens/my_project_screen.dart';
import '../features/projects/screens/project_edit_screen.dart';
import '../features/projects/widgets/working_hours_editor.dart';
import '../features/projects/widgets/social_links_editor.dart';
import '../features/projects/screens/location_picker_screen.dart';
import '../features/projects/screens/pending_approval_screen.dart';
import '../features/projects/screens/disabled_project_screen.dart';
import '../features/products/screens/product_list_screen.dart';
import '../features/products/screens/product_form_screen.dart';
import '../features/products/screens/product_detail_screen.dart'
    as product_detail;
import '../features/support/screens/support_tickets_screen.dart';
import '../features/support/screens/create_ticket_screen.dart';
import '../features/support/screens/ticket_detail_screen.dart';
import '../features/transactions/screens/transactions_screen.dart';
import '../features/transactions/screens/transaction_detail_screen.dart';
import '../features/transactions/screens/create_review_screen.dart';
import '../shared/widgets/main_scaffold.dart';
import '../data/providers/auth_provider.dart';
import '../core/localization/app_localizations.dart';

// Route names
class Routes {
  Routes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerProjectOwner = '/register/project-owner';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String conversations = '/conversations';
  static const String chat = '/chat/:conversationId';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String settings = '/settings';
  static const String productDetail = '/product/:productId';
  static const String projectDetail = '/project/:projectId';
  static const String projectEdit = '/project/edit';
  static const String projectWorkingHours = '/project/edit/working-hours';
  static const String projectSocialLinks = '/project/edit/social-links';
  static const String projectLocation = '/project/edit/location';
  static const String pendingApproval = '/project/pending';
  static const String projectDisabled = '/project/disabled';
  static const String myProject = '/my-project';
  static const String notifications = '/notifications';
  static const String allCategories = '/categories';
  static const String categoryProducts = '/categories/:categoryId/products';
  static const String projectProducts = '/project/:projectId/products';
  static const String productForm = '/product/form';
  static const String supportTickets = '/support/tickets';
  static const String createTicket = '/support/tickets/new';
  static const String ticketDetail = '/support/tickets/:ticketId';
  static const String transactions = '/transactions';
  static const String transactionDetail = '/transactions/:transactionId';
  static const String createReview = '/transactions/:transactionId/review';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoggedIn = authState.isAuthenticated;
      final location = state.matchedLocation;

      // Don't redirect from splash or onboarding
      if (location == Routes.splash || location == Routes.onboarding) {
        return null;
      }

      // Auth pages (accessible without login)
      final isAuthPage = location == Routes.login ||
          location == Routes.register ||
          location == Routes.registerProjectOwner ||
          location == Routes.forgotPassword ||
          location.startsWith(Routes.resetPassword);

      // Protected routes that require login
      final protectedRoutes = [
        Routes.cart,
        Routes.conversations,
        Routes.profile,
        Routes.editProfile,
        Routes.changePassword,
        Routes.myProject,
      ];

      final isProtectedRoute =
          protectedRoutes.any((route) => location.startsWith(route));

      // Redirect to login if accessing protected route without auth
      if (!isLoggedIn && isProtectedRoute) {
        return Routes.login;
      }

      // Redirect to home if logged in and accessing auth pages
      if (isLoggedIn && isAuthPage) {
        return Routes.home;
      }

      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes (outside shell)
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.registerProjectOwner,
        builder: (context, state) => const ProjectOwnerRegisterScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      // Profile routes (outside shell, but require auth)
      GoRoute(
        path: Routes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),

      // Project routes
      GoRoute(
        path: Routes.myProject,
        builder: (context, state) => const MyProjectScreen(),
      ),
      GoRoute(
        path: Routes.projectEdit,
        builder: (context, state) => const ProjectEditScreen(),
      ),
      GoRoute(
        path: Routes.projectWorkingHours,
        builder: (context, state) => const WorkingHoursEditor(),
      ),
      GoRoute(
        path: Routes.projectSocialLinks,
        builder: (context, state) => const SocialLinksEditor(),
      ),
      GoRoute(
        path: Routes.projectLocation,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LocationPickerScreen(
            initialLatitude: extra?['latitude'] as double?,
            initialLongitude: extra?['longitude'] as double?,
          );
        },
      ),
      GoRoute(
        path: Routes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: Routes.projectDisabled,
        builder: (context, state) => const DisabledProjectScreen(),
      ),
      GoRoute(
        path: Routes.projectDetail,
        builder: (context, state) {
          final projectId = int.parse(state.pathParameters['projectId']!);
          return ProjectDetailScreen(projectId: projectId);
        },
      ),

      // All categories screen
      GoRoute(
        path: Routes.allCategories,
        builder: (context, state) => const AllCategoriesScreen(),
      ),

      // Category Products
      GoRoute(
        path: Routes.categoryProducts,
        builder: (context, state) {
          final categoryId = int.parse(state.pathParameters['categoryId']!);
          return ProductListScreen(categoryId: categoryId);
        },
      ),

      // Project Products
      GoRoute(
        path: Routes.projectProducts,
        builder: (context, state) {
          final projectId = int.parse(state.pathParameters['projectId']!);
          final extra = state.extra as Map<String, dynamic>?;
          final isOwner = extra?['isOwner'] as bool? ?? false;
          return ProductListScreen(
            projectId: projectId,
            isOwner: isOwner,
          );
        },
      ),

      // Product Detail
      GoRoute(
        path: Routes.productDetail,
        builder: (context, state) {
          final productId = int.parse(state.pathParameters['productId']!);
          return product_detail.ProductDetailScreen(productId: productId);
        },
      ),

      // Product Form
      GoRoute(
        path: Routes.productForm,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final projectId = extra?['projectId'] as int;
          final product = extra?['product']; // Cast to Product if needed
          return ProductFormScreen(
            projectId: projectId,
            product: product,
          );
        },
      ),

      // Chat
      GoRoute(
        path: Routes.chat,
        builder: (context, state) {
          final conversationId =
              int.parse(state.pathParameters['conversationId']!);
          return ChatScreen(conversationId: conversationId);
        },
      ),

      // Notifications
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Support Tickets
      GoRoute(
        path: Routes.supportTickets,
        builder: (context, state) => const SupportTicketsScreen(),
      ),
      GoRoute(
        path: Routes.createTicket,
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: Routes.ticketDetail,
        builder: (context, state) {
          final ticketId = int.parse(state.pathParameters['ticketId']!);
          return TicketDetailScreen(ticketId: ticketId);
        },
      ),

      // Transactions
      GoRoute(
        path: Routes.transactions,
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: Routes.transactionDetail,
        builder: (context, state) {
          final transactionId =
              int.parse(state.pathParameters['transactionId']!);
          return TransactionDetailScreen(transactionId: transactionId);
        },
      ),
      GoRoute(
        path: Routes.createReview,
        builder: (context, state) {
          final transactionId =
              int.parse(state.pathParameters['transactionId']!);
          // productId should be passed via extra or query params
          final productId = state.uri.queryParameters['productId'];
          return CreateReviewScreen(
            transactionId: transactionId,
            productId: productId != null ? int.parse(productId) : 0,
          );
        },
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.search,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchScreen(),
            ),
          ),
          GoRoute(
            path: Routes.cart,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartScreen(),
            ),
          ),
          GoRoute(
            path: Routes.conversations,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversationsScreen(),
            ),
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = context.l10n;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                l10n.tr('pageNotFound'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('${state.uri}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(Routes.home),
                child: Text(l10n.tr('returnHome')),
              ),
            ],
          ),
        ),
      );
    },
  );
});
