import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty) {
        return Uri(scheme: 'http', host: host, port: 5000).origin;
      }
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:5000';
    }
    // Physical Android devices use the development PC's LAN address.
    return 'http://192.168.0.112:5000';
  }

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String currentUser = '/api/auth/me';
  static const String profile = '/api/profile';
  static const String signup = '/api/auth/signup';
  static const String logout = '/api/auth/logout';

  // Student endpoints
  static const String studentDashboard = '/api/student/dashboard';
  static const String studentCourses = '/api/student/courses';
  static const String studentTests = '/api/student/tests';
  static const String studentSubmitTest = '/api/student/tests/submit';
  static const String studentPerformance = '/api/student/performance';
  static const String studentReportBug = '/api/student/report-bug';

  // Instructor endpoints
  static const String instructorDashboard = '/api/instructor/dashboard';
  static const String instructorCourses = '/api/instructor/courses';
  static const String instructorExams = '/api/instructor/exams';
  static const String instructorStudents = '/api/instructor/students';
  static const String instructorReportBug = '/api/instructor/report-bug';

  // Admin endpoints
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminCourses = '/api/admin/courses';
  static const String adminUsers = '/api/admin/users';
  static const String adminContent = '/api/admin/content';

  // Reports
  static const String reports = '/api/reports';
  static const String myReports = '/api/reports/mine';

  // Discussion endpoints
  static const String discussions = '/api/discussions';

  // Study circles
  static const String studyCircles = '/api/study-circles';

  // Health
  static const String health = '/api/health';

  // Packages
  static const String packages = '/api/packages';
  static String demoPurchase(int packageId) =>
      '/api/student/packages/$packageId/demo-purchase';
  static const String adminPackages = '/api/admin/packages';
}
