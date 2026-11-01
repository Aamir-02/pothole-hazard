import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pothole_hazard/features/auth/login_screen.dart';
import 'package:pothole_hazard/features/auth/signup_screen.dart';
import 'package:pothole_hazard/features/auth/forgot_password_screen.dart';

void main() {
  group('LoginScreen Tests', () {
    testWidgets('Email and password fields are initially empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      // Verify email field is empty
      final emailField = tester.widget<TextFormField>(textFields.at(0));
      expect(emailField.controller?.text, '');

      // Verify password field is empty
      final passwordField = tester.widget<TextFormField>(textFields.at(1));
      expect(passwordField.controller?.text, '');
    });

    testWidgets('Validation error displayed when submitting empty login fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap Sign In button
      final signInButton = find.widgetWithText(ElevatedButton, 'SIGN IN TO RIDE');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Validation error displayed for invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'invalid-email-format');
      await tester.enterText(textFields.at(1), 'password123');

      final signInButton = find.widgetWithText(ElevatedButton, 'SIGN IN TO RIDE');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('Password visibility toggle toggles obscureText', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextField);
      final passwordField = textFields.at(1);

      // Initially obscureText is true
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      // Find visibility toggle icon button
      final visibilityIcon = find.byIcon(Icons.visibility_off_outlined);
      expect(visibilityIcon, findsOneWidget);
      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      // obscureText should now be false
      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });
  });

  group('SignupScreen Tests', () {
    testWidgets('All fields are initially empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      // Name, Email, Phone, Password, Confirm Password
      expect(textFields, findsNWidgets(5));

      for (int i = 0; i < 5; i++) {
        final field = tester.widget<TextFormField>(textFields.at(i));
        expect(field.controller?.text, '');
      }
    });

    testWidgets('Validation errors when required fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      final createAccountBtn = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
      expect(createAccountBtn, findsOneWidget);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('Validates password and confirm password matching', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'John Rider');
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.enterText(textFields.at(3), 'SecurePass123!');
      await tester.enterText(textFields.at(4), 'MismatchedPass123!');

      final createAccountBtn = find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT');
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Tests', () {
    testWidgets('Validates email format on reset request', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      final button = find.widgetWithText(ElevatedButton, 'SEND RESET LINK');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address'), findsOneWidget);
    });
  });
}
