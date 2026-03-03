import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// removed unnecessary import
import 'screens/home_screen.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/get_started_screen.dart';
import 'screens/profile/change_password_screen.dart';
import 'screens/support/privacy_policy_screen.dart';
import 'screens/support/help_support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed (continue without Firebase): $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Classical AI Tools App',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              appBarTheme: AppBarTheme(
                backgroundColor: ColorScheme.fromSeed(seedColor: Colors.blue).primary,
                foregroundColor: Colors.white,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              scaffoldBackgroundColor: Colors.white,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E1E1E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
            ),
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/auth_wrapper': (context) => const AuthWrapper(),
              '/get-started': (context) => const GetStartedScreen(),
              '/login': (context) => const LoginScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/history': (context) => const HistoryScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/change-password': (context) => const ChangePasswordScreen(),
              '/privacy-policy': (context) => const PrivacyPolicyScreen(),
              '/help-support': (context) => const HelpSupportScreen(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // If not logged in
        return const GetStartedScreen();
      },
    );
  }
}
