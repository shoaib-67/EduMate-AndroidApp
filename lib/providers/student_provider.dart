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
  String? _dashboardError;

  // Courses
  List<Course> _courses = [];
  bool _isCoursesLoading = false;
  bool _coursesLoaded = false;
  String? _coursesError;

  // Tests
  List<MockTest> _tests = [];
  bool _isTestsLoading = false;
  bool _testsLoaded = false;

  // Performance
  Performance? _performance;
  bool _isPerformanceLoading = false;
  bool _performanceLoaded = false;
  String? _performanceError;

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
  String? get dashboardError => _dashboardError;
  List<Course> get courses => _courses;
  bool get isCoursesLoading => _isCoursesLoading;
  bool get coursesLoaded => _coursesLoaded;
  String? get coursesError => _coursesError;
  List<MockTest> get tests => _tests;
  bool get isTestsLoading => _isTestsLoading;
  bool get testsLoaded => _testsLoaded;
  Performance? get performance => _performance;
  bool get isPerformanceLoading => _isPerformanceLoading;
  bool get performanceLoaded => _performanceLoaded;
  String? get performanceError => _performanceError;
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
    _dashboardError = null;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await _service.getDashboard();
    } catch (error) {
      _dashboardData = null;
      _dashboardError = error.toString().replaceFirst('Exception: ', '');
      _error = _dashboardError;
    } finally {
      _dashboardLoaded = true;
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCourses() async {
    _isCoursesLoading = true;
    _coursesError = null;
    notifyListeners();

    try {
      _courses = await _service.getCourses();
    } catch (error) {
      _courses = [];
      _coursesError = error.toString().replaceFirst('Exception: ', '');
      _error = _coursesError;
    } finally {
      _coursesLoaded = true;
      _isCoursesLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getCourseDetails(int courseId) {
    return _service.getCourseDetails(courseId);
  }

  Future<ApiResponse> rateCourse(int courseId, int rating) {
    return _service.rateCourse(courseId, rating);
  }

  Future<List<PackagePlan>> getPackages() => _service.getPackages();

  Future<ApiResponse> demoPurchase(int packageId) async {
    final response = await _service.demoPurchase(packageId);
    if (response.success) {
      await Future.wait([loadCourses(), loadDashboard(), loadTests()]);
    }
    return response;
  }

  Future<void> loadTests() async {
    _isTestsLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tests = await _service.getTests();
    } catch (error) {
      _tests = [];
      _error = error.toString();
    } finally {
      _testsLoaded = true;
      _isTestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPerformance() async {
    _isPerformanceLoading = true;
    _performanceError = null;
    notifyListeners();

    try {
      _performance = await _service.getPerformance();
    } catch (error) {
      _performance = null;
      _performanceError = error.toString().replaceFirst('Exception: ', '');
      _error = _performanceError;
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

  Future<Discussion?> getDiscussion(int id) => _service.getDiscussion(id);

  Future<List<Discussion>> getCourseDiscussions(int courseId) =>
      _service.getDiscussions(courseId: courseId);

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

  Future<bool> createCourseDiscussion(
    int courseId,
    String title,
    String content,
  ) async {
    final response = await _service.createDiscussion(
      title,
      content,
      courseId: courseId,
    );
    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }
    return response.success;
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

  Future<ApiResponse> submitTest(
    int testId,
    Map<int, dynamic> answers, {
    String? submissionId,
    String reason = 'manual',
  }) async {
    final response = await _service.submitTest(
      testId,
      answers,
      submissionId: submissionId,
      reason: reason,
    );
    if (!response.success) {
      _error = response.message;
      notifyListeners();
    }
    if (response.success) await loadTests();
    return response;
  }

  Future<MockTest?> getTestDetails(int testId) async {
    _error = null;
    try {
      return await _service.getTestDetails(testId);
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
