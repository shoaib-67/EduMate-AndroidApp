import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/course_content.dart';
import '../models/instructor_student_result.dart';
import '../services/api_service.dart';
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
  List<InstructorStudentResult> _studentResults = [];
  bool _isResultsLoading = false;
  bool _resultsLoaded = false;
  String? _resultsError;
  List<dynamic> _myBugReports = [];
  bool _myBugReportsLoaded = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get isDashboardLoading => _isDashboardLoading;
  bool get dashboardLoaded => _dashboardLoaded;
  List<Course> get courses => _courses;
  bool get isCoursesLoading => _isCoursesLoading;
  bool get coursesLoaded => _coursesLoaded;
  List<InstructorStudentResult> get studentResults => _studentResults;
  bool get isResultsLoading => _isResultsLoading;
  bool get resultsLoaded => _resultsLoaded;
  String? get resultsError => _resultsError;
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

  Future<List<Map<String, dynamic>>> getCourseExams(int courseId) =>
      _service.getCourseExams(courseId);

  Future<Map<String, dynamic>> getExam(int examId) => _service.getExam(examId);

  Future<ApiResponse> createExam(int courseId, Map<String, dynamic> data) =>
      _service.createExam(courseId, data);

  Future<ApiResponse> updateExam(int examId, Map<String, dynamic> data) =>
      _service.updateExam(examId, data);

  Future<ApiResponse> publishExam(int examId, bool published) =>
      _service.publishExam(examId, published);

  Future<ApiResponse> deleteExam(int examId) => _service.deleteExam(examId);

  Future<void> loadStudentResults() async {
    _isResultsLoading = true;
    _resultsError = null;
    notifyListeners();
    try {
      _studentResults = await _service.getStudentResults();
    } catch (error) {
      _studentResults = [];
      _resultsError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _resultsLoaded = true;
      _isResultsLoading = false;
      notifyListeners();
    }
  }

  Future<List<InstructorExamResult>> getStudentExamResults(int studentId) =>
      _service.getStudentExamResults(studentId);

  Future<bool> reportBug(String title, String description) async {
    final response = await _service.reportBug(title, description);
    return response.success;
  }
}
