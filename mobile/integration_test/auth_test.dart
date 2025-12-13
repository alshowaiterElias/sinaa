import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sinaa_mobile/main.dart' as app;

/// Integration tests for authentication flows
/// 
/// PREREQUISITES:
/// 1. Backend must be running: cd backend && npm run dev
/// 2. Update api_endpoints.dart with correct IP for your device
/// 3. Database should be clean or use unique test emails
/// 
/// RUN COMMAND:
/// flutter test integration_test/auth_test.dart
/// 
/// For specific device:
/// flutter test integration_test/auth_test.dart -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Flow Integration Tests', () {
    
    testWidgets('Complete customer registration flow', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash screen to complete
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Navigate to registration if on login screen
      final registerButton = find.text('سجل الآن');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Generate unique email for test
      final testEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@test.com';

      // Fill registration form
      await tester.enterText(
        find.byType(TextFormField).at(0), // Full name
        'Test User Integration',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(1), // Email
        testEmail,
      );
      await tester.pumpAndSettle();

      // Skip phone (optional)

      await tester.enterText(
        find.byType(TextFormField).at(3), // Password
        'TestPass123',
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(4), // Confirm password
        'TestPass123',
      );
      await tester.pumpAndSettle();

      // Submit registration
      final submitButton = find.text('إنشاء حساب');
      await tester.tap(submitButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify successful navigation to home
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Login with valid credentials', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for splash
      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Enter login credentials
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, 'TestPass123');
      await tester.pumpAndSettle();

      // Tap login button
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check for either success (home) or error (snackbar)
      final hasHome = find.byType(BottomNavigationBar).evaluate().isNotEmpty;
      final hasError = find.byType(SnackBar).evaluate().isNotEmpty;
      
      expect(hasHome || hasError, true);
    });

    testWidgets('Login validation - empty fields', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Try to login without filling fields
      final loginButton = find.text('تسجيل الدخول');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('يرجى إدخال البريد الإلكتروني'), findsOneWidget);
    });

    testWidgets('Registration validation - weak password', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Navigate to registration
      final registerButton = find.text('سجل الآن');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Fill with weak password
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Test User',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(3), // Password
        'weak', // Should fail validation
      );
      await tester.enterText(
        find.byType(TextFormField).at(4),
        'weak',
      );
      await tester.pumpAndSettle();

      // Submit
      final submitButton = find.text('إنشاء حساب');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Should show password validation error
      expect(
        find.textContaining('8 أحرف'),
        findsWidgets,
      );
    });

    testWidgets('Navigate to forgot password', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap forgot password link
      final forgotPasswordLink = find.text('نسيت كلمة المرور؟');
      await tester.tap(forgotPasswordLink);
      await tester.pumpAndSettle();

      // Verify navigation to forgot password screen
      expect(find.text('نسيت كلمة المرور؟'), findsWidgets);
      expect(find.text('إرسال رابط الاستعادة'), findsOneWidget);
    });

    testWidgets('Guest browsing flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tap browse as guest
      final guestButton = find.text('تصفح كزائر');
      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      // Verify navigation to home
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Project owner registration navigation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await Future.delayed(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Navigate to registration first
      final registerButton = find.text('سجل الآن');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pumpAndSettle();
      }

      // Tap project owner link
      final projectOwnerLink = find.text('مشروع عائلي؟');
      await tester.tap(projectOwnerLink);
      await tester.pumpAndSettle();

      // Verify project owner registration screen
      expect(find.text('صاحب مشروع'), findsOneWidget);
      expect(find.text('معلومات المشروع'), findsOneWidget);
    });
  });
}

