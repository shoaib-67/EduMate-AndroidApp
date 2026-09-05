import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/student_service.dart';
import 'services/instructor_service.dart';
import 'services/admin_service.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'providers/instructor_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/student/performance_screen.dart';
import 'screens/student/discussion_screen.dart';
import 'screens/student/packages_screen.dart';
import 'screens/student/student_profile_screen.dart';
import 'screens/student/report_bug_screen.dart';
import 'screens/student/test_taking_screen.dart';
import 'screens/instructor/instructor_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'models/mock_test.dart';
import 'widgets/common_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surfaceColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final apiService = ApiService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => StudentProvider(StudentService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => InstructorProvider(InstructorService(apiService)),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(AdminService(apiService)),
        ),
      ],
      child: const EduMateApp(),
    ),
  );
}

class EduMateApp extends StatelessWidget {
  const EduMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AuthGate(),
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/login':
        page = const LoginScreen();
        break;
      case '/signup':
        page = const SignupScreen();
        break;
      case '/student':
        page = const StudentDashboard();
        break;
      case '/student/performance':
        page = const PerformanceScreen();
        break;
      case '/student/discussions':
        page = const DiscussionScreen();
        break;
      case '/student/packages':
        page = const PackagesScreen();
        break;
      case '/student/profile':
        page = const StudentProfileScreen();
        break;
      case '/student/report-bug':
        page = const ReportBugScreen();
        break;
      case '/student/test':
        final test = settings.arguments as MockTest;
        page = TestTakingScreen(test: test);
        break;
      case '/instructor':
        page = const InstructorDashboard();
        break;
      case '/instructor/report-bug':
        page = const ReportBugScreen(isInstructor: true);
        break;
      case '/admin':
        page = const AdminDashboard();
        break;
      default:
        page = const LoginScreen();
    }

    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Widget _dashboardForRole(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
      case 'instructor':
        return const InstructorDashboard();
      case 'admin':
        return const AdminDashboard();
      case 'student':
      default:
        return const StudentDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show splash while initializing
        if (!auth.isInitialized) {
          return const _SplashScreen();
        }

        // Route based on auth state
        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        return _dashboardForRole(auth.userRole);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(102),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'EduMate',
              style: Theme.of(context).textTheme.displayMedium
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার প্রস্তুতির সঙ্গী',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            const LoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
