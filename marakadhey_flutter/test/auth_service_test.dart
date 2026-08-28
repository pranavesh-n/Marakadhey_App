import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marakadhey_mobile/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Strict Validation & Auth Flow Tests', () {
    test('Email format validation accepts Outlook, Zoho, Gmail and rejects malformed', () {
      expect(AuthService.isValidEmail('user@outlook.com'), isTrue);
      expect(AuthService.isValidEmail('john.doe@zoho.com'), isTrue);
      expect(AuthService.isValidEmail('developer@gmail.com'), isTrue);
      expect(AuthService.isValidEmail('support@company.co.in'), isTrue);

      expect(AuthService.isValidEmail('invalid'), isFalse);
      expect(AuthService.isValidEmail('invalid@'), isFalse);
      expect(AuthService.isValidEmail('@domain.com'), isFalse);
      expect(AuthService.isValidEmail('test@domain'), isFalse);
    });

    test('Signing in with non-existent email returns accountNotFound and does NOT log in', () async {
      final auth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));

      final result = await auth.loginWithEmail('nobody@outlook.com', 'password123');

      expect(result.status, equals(AuthStatus.accountNotFound));
      expect(result.isSuccess, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('Registration creates account, logs in user, and rejects duplicate registration', () async {
      final auth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));

      // Register new user
      final regResult = await auth.registerWithEmail(
        'Pranavesh',
        'pranavesh@zoho.com',
        'Secret@123',
      );

      expect(regResult.status, equals(AuthStatus.success));
      expect(regResult.isSuccess, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.email, equals('pranavesh@zoho.com'));
      expect(auth.currentUser?.displayName, equals('Pranavesh'));

      // Attempt duplicate registration
      final dupResult = await auth.registerWithEmail(
        'Duplicate Name',
        'pranavesh@zoho.com',
        'DifferentPass',
      );
      expect(dupResult.status, equals(AuthStatus.emailAlreadyInUse));
      expect(dupResult.isSuccess, isFalse);
    });

    test('Sign in with wrong password is rejected and keeps user logged out', () async {
      final auth = AuthService();
      await Future.delayed(const Duration(milliseconds: 50));

      // Register user first
      await auth.registerWithEmail(
        'Test User',
        'user@outlook.com',
        'correctPassword123',
      );

      // Log out
      await auth.logout();
      expect(auth.isLoggedIn, isFalse);

      // Attempt sign in with wrong password
      final wrongResult = await auth.loginWithEmail('user@outlook.com', 'wrongPassword');
      expect(wrongResult.status, equals(AuthStatus.wrongPassword));
      expect(wrongResult.isSuccess, isFalse);
      expect(auth.isLoggedIn, isFalse);

      // Attempt sign in with correct password
      final correctResult = await auth.loginWithEmail('user@outlook.com', 'correctPassword123');
      expect(correctResult.status, equals(AuthStatus.success));
      expect(correctResult.isSuccess, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.email, equals('user@outlook.com'));
    });
  });
}
