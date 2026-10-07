import '../config/api_config.dart';
import '../models/course.dart';
import '../models/course_content.dart';
import 'api_service.dart';

class InstructorService {
  final ApiService _api;

  InstructorService(this._api);

  Future<Map<String, dynamic>?> getDashboard() async {
    final response = await _api.get(ApiConfig.instructorDashboard);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<List<Course>> getCourses() async {
    final response = await _api.get(ApiConfig.instructorCourses);
    if (response.success && response.data != null) {
      final list = response.data is Map
          ? (response.data['courses'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
      return list
          .map((c) => Course.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<CourseContent>> getCourseContent(int courseId) async {
    final response = await _api.get(
      '${ApiConfig.instructorCourses}/$courseId/content',
    );
    if (response.success && response.data is Map) {
      return ((response.data['content'] as List<dynamic>?) ?? [])
          .map((item) => CourseContent.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ApiResponse> addCourseContent(
    int courseId,
    Map<String, dynamic> data,
  ) async {
    return await _api.post(
      '${ApiConfig.instructorCourses}/$courseId/content',
      body: data,
    );
  }

  Future<ApiResponse> deleteCourseContent(int courseId, int contentId) async {
    return await _api.delete(
      '${ApiConfig.instructorCourses}/$courseId/content/$contentId',
    );
  }

  Future<List<Map<String, dynamic>>> getCourseExams(int courseId) async {
    final response = await _api.get(
      '${ApiConfig.instructorCourses}/$courseId/exams',
    );
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to load exams');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['exams'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getExam(int examId) async {
    final response = await _api.get('${ApiConfig.instructorExams}/$examId');
    if (!response.success) {
      throw Exception(response.message ?? 'Unable to load exam');
    }
    return Map<String, dynamic>.from((response.data as Map)['exam'] as Map);
  }

  Future<ApiResponse> createExam(int courseId, Map<String, dynamic> data) =>
      _api.post('${ApiConfig.instructorCourses}/$courseId/exams', body: data);

  Future<ApiResponse> updateExam(int examId, Map<String, dynamic> data) =>
      _api.put('${ApiConfig.instructorExams}/$examId', body: data);

  Future<ApiResponse> publishExam(int examId, bool published) => _api.patch(
    '${ApiConfig.instructorExams}/$examId/publish',
    body: {'published': published},
  );

  Future<ApiResponse> deleteExam(int examId) =>
      _api.delete('${ApiConfig.instructorExams}/$examId');

  Future<List<dynamic>> getStudentResults() async {
    final response = await _api.get(ApiConfig.instructorStudents);
    if (response.success && response.data != null) {
      return response.data is Map
          ? (response.data['students'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await _api.get(ApiConfig.instructorProfile);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    return await _api.put(ApiConfig.instructorProfile, body: data);
  }

  Future<ApiResponse> reportBug(String title, String description) async {
    return await _api.post(
      ApiConfig.instructorReportBug,
      body: {'title': title, 'description': description},
    );
  }

  Future<List<dynamic>> getMyBugReports() async {
    final response = await _api.get(ApiConfig.myReports);
    if (response.success && response.data is Map) {
      return (response.data['reports'] as List<dynamic>? ?? []);
    }
    return [];
  }
}
