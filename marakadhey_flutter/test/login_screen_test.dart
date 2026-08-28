import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marakadhey_mobile/screens/login_screen.dart';
import 'package:marakadhey_mobile/services/auth_service.dart';
import 'package:marakadhey_mobile/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen displays No Account Found dialog when non-existent email logs in', (tester) async {
    // Set realistic mobile phone screen dimensions
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authService = AuthService();
    final securityService = SecurityService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
          ChangeNotifierProvider.value(value: securityService),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify on Sign In tab
    expect(find.text('Sign In to My Account'), findsOneWidget);

    // 2. Enter email and password
    final emailField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);

    await tester.enterText(emailField, 'brandnewuser@outlook.com');
    await tester.enterText(passwordField, 'password1234');
    await tester.pump();

    // 3. Tap "Sign In to My Account"
    final submitButton = find.text('Sign In to My Account');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 4. Verify "No Account Found" dialog appears
    expect(find.text('No Account Found'), findsOneWidget);
    expect(find.text('No registered account was found for:'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);

    // 5. Tap "Create New Account" in dialog
    await tester.tap(find.text('Create New Account'));
    await tester.pumpAndSettle();

    // 6. Verify switched to Create Account mode and email is preserved
    expect(find.text('Create My Account'), findsOneWidget);
    expect(find.text('brandnewuser@outlook.com'), findsOneWidget);
  });
}
