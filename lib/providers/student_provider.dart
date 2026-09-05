import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/mock_test.dart';
import '../models/discussion.dart';
import '../models/performance.dart';
import '../services/student_service.dart';
import '../models/package_plan.dart';
import '../services/api_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _service;

  StudentProvider(this._service);

  // Dashboard
  Map<String, dynamic>? _dashboardData;
  bool _isDashboardLoading = false;
  bool _dashboardLoaded = false;

  // Courses
  List<Course> _courses = [];
  bool _isCoursesLoading = false;
  bool _coursesLoaded = false;

  // Tests
  List<MockTest> _tests = [];
  bool _isTestsLoading = false;
  bool _testsLoaded = false;

  // Performance
  Performance? _performance;
  bool _isPerformanceLoading = false;
  bool _performanceLoaded = false;

  // Discussions
  List<Discussion> _discussions = [];
  bool _isDiscussionsLoading = false;
  bool _discussionsLoaded = false;

  String? _error;
  List<dynamic> _myBugReports = [];
  bool _myBugReportsLoaded = false;

  // Getters
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get dashboardLoaded => _dashboardLoaded;
  List<Course> get courses => _courses;
  bool get isCoursesLoading => _isCoursesLoading;
  bool get coursesLoaded => _coursesLoaded;
  List<MockTest> get tests => _tests;
  bool get isTestsLoading => _isTestsLoading;
  bool get testsLoaded => _testsLoaded;
  Performance? get performance => _performance;
  bool get isPerformanceLoading => _isPerformanceLoading;
  bool get performanceLoaded => _performanceLoaded;
  List<Discussion> get discussions => _discussions;
  bool get isDiscussionsLoading => _isDiscussionsLoading;
  bool get discussionsLoaded => _discussionsLoaded;
  String? get error => _error;
  List<dynamic> get myBugReports => _myBugReports;
  bool get myBugReportsLoaded => _myBugReportsLoaded;

  Future<void> loadMyBugReports() async {
    _myBugReports = await _service.getMyBugReports();
    _myBugReportsLoaded = true;
    notifyListeners();
  }

  Future<void> loadDashboard() async {
    _isDashboardLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await _service.getDashboard();
    } catch (_) {
      _dashboardData = null;
      _error = 'ড্যাশবোর্ডের তথ্য পাওয়া যায়নি';
    } finally {
      _dashboardLoaded = true;
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourses() async {
    _isCoursesLoading = true;
    notifyListeners();

    try {
      _courses = await _service.getCourses();
    } catch (_) {
      _courses = [];
      _error = 'কোর্সের তথ্য পাওয়া যায়নি';
    } finally {
      _coursesLoaded = true;
      _isCoursesLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getCourseDetails(int courseId) {
    return _service.getCourseDetails(courseId);
  }

  Future<List<PackagePlan>> getPackages() => _service.getPackages();

  Future<void> loadTests() async {
    _isTestsLoading = true;
    notifyListeners();

    try {
      _tests = await _service.getTests();
    } catch (_) {
      _tests = [];
      _error = 'টেস্টের তথ্য পাওয়া যায়নি';
    } finally {
      _testsLoaded = true;
      _isTestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPerformance() async {
    _isPerformanceLoading = true;
    notifyListeners();

    try {
      _performance = await _service.getPerformance();
    } catch (_) {
      _performance = null;
      _error = 'পারফরম্যান্সের তথ্য পাওয়া যায়নি';
    } finally {
      _performanceLoaded = true;
      _isPerformanceLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDiscussions() async {
    _isDiscussionsLoading = true;
    notifyListeners();

    try {
      _discussions = await _service.getDiscussions();
    } catch (_) {
      _discussions = [];
      _error = 'আলোচনার তথ্য পাওয়া যায়নি';
    } finally {
      _discussionsLoaded = true;
      _isDiscussionsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDiscussion(String title, String content) async {
    final response = await _service.createDiscussion(title, content);
    if (response.success) {
      await loadDiscussions();
      return true;
    }
    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<bool> replyToDiscussion(int id, String content) async {
    final response = await _service.replyToDiscussion(id, content);
    if (response.success) {
      await loadDiscussions();
      return true;
    }
    return false;
  }

  Future<bool> reportBug(String title, String description) async {
    final response = await _service.reportBug(title, description);
    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }
    return response.success;
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    final response = await _service.updateProfile(data);
    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }
    return response;
  }

  Future<bool> submitTest(int testId, Map<int, int> answers) async {
    final response = await _service.submitTest(testId, answers);
    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }
    return response.success;
  }

  Future<MockTest?> getTestDetails(int testId) {
    return _service.getTestDetails(testId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
