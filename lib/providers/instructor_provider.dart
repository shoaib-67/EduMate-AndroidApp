import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/course_content.dart';
import '../services/instructor_service.dart';

class InstructorProvider extends ChangeNotifier {
  final InstructorService _service;

  InstructorProvider(this._service);

  Map<String, dynamic>? _dashboardData;
  bool _isDashboardLoading = false;
  bool _dashboardLoaded = false;
  List<Course> _courses = [];
  bool _isCoursesLoading = false;
  bool _coursesLoaded = false;
  List<dynamic> _studentResults = [];
  bool _isResultsLoading = false;
  bool _resultsLoaded = false;
  String? _error;
  List<dynamic> _myBugReports = [];
  bool _myBugReportsLoaded = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get dashboardLoaded => _dashboardLoaded;
  List<Course> get courses => _courses;
  bool get isCoursesLoading => _isCoursesLoading;
  bool get coursesLoaded => _coursesLoaded;
  List<dynamic> get studentResults => _studentResults;
  bool get isResultsLoading => _isResultsLoading;
  bool get resultsLoaded => _resultsLoaded;
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
    notifyListeners();
    try {
      _dashboardData = await _service.getDashboard();
    } catch (_) {
      _dashboardData = null;
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
    } finally {
      _coursesLoaded = true;
      _isCoursesLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCourse(Map<String, dynamic> data) async {
    final response = await _service.createCourse(data);
    if (response.success) {
      await loadCourses();
      return true;
    }
    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<bool> updateCourse(int id, Map<String, dynamic> data) async {
    final response = await _service.updateCourse(id, data);
    if (response.success) {
      await loadCourses();
      return true;
    }
    _error = response.message;
    notifyListeners();
    return false;
  }

  Future<bool> deleteCourse(int id) async {
    final response = await _service.deleteCourse(id);
    if (response.success) {
      await loadCourses();
      return true;
    }
    return false;
  }

  Future<List<CourseContent>> getCourseContent(int courseId) {
    return _service.getCourseContent(courseId);
  }

  Future<bool> addCourseContent(int courseId, Map<String, dynamic> data) async {
    final response = await _service.addCourseContent(courseId, data);
    return response.success;
  }

  Future<bool> deleteCourseContent(int courseId, int contentId) async {
    final response = await _service.deleteCourseContent(courseId, contentId);
    return response.success;
  }

  Future<bool> createExam(Map<String, dynamic> data) async {
    final response = await _service.createExam(data);
    return response.success;
  }

  Future<void> loadStudentResults() async {
    _isResultsLoading = true;
    notifyListeners();
    try {
      _studentResults = await _service.getStudentResults();
    } catch (_) {
      _studentResults = [];
    } finally {
      _resultsLoaded = true;
      _isResultsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reportBug(String title, String description) async {
    final response = await _service.reportBug(title, description);
    return response.success;
  }
}
