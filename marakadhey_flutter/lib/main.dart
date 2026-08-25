import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'providers/opportunity_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/screen_lock_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/security_service.dart';
import 'services/share_receiver_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.headerBg,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize notifications
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // Initialize Android Share Target Receiver
  ShareReceiverService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => OpportunityProvider()),
        ChangeNotifierProvider(create: (_) => SecurityService()),
      ],
      child: const MarakadheyApp(),
    ),
  );
}

class MarakadheyApp extends StatefulWidget {
  const MarakadheyApp({super.key});

  @override
  State<MarakadheyApp> createState() => _MarakadheyAppState();
}

class _MarakadheyAppState extends State<MarakadheyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final security = context.read<SecurityService>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.hidden || state == AppLifecycleState.detached) {
      security.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      security.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marakadhey Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.headerBg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      builder: (context, child) {
        return Consumer2<AuthService, SecurityService>(
          builder: (context, auth, security, _) {
            final isScreenLocked = auth.isLoggedIn && security.isPinEnabled && security.isLocked;
            return ResponsiveMobileWrapper(
              child: Stack(
                children: [
                  child ?? const SizedBox(),
                  if (isScreenLocked)
                    const Positioned.fill(
                      child: ScreenLockScreen(),
                    ),
                ],
              ),
            );
          },
        );
      },
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.headerBg,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          if (auth.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<OpportunityProvider>().setUserId(auth.currentUser?.uid);
              }
            });

            return const MainNavigationScreen();
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<OpportunityProvider>().setUserId(null);
              }
            });
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 600;

    if (!isDesktop) {
      return child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Branding Watermark
          Positioned(
            top: 24,
            left: 32,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/logo.png', width: 28, height: 28, fit: BoxFit.contain),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marakadhey Mobile',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'INTERACTIVE MOBILE PREVIEW (EMULATOR)',
                      style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Centered Smartphone Mockup Frame
          Center(
            child: Container(
              width: 412,
              height: 840,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF334155), width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
