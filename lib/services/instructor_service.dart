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

  Future<ApiResponse> createCourse(Map<String, dynamic> data) async {
    return await _api.post(ApiConfig.instructorCourses, body: data);
  }

  Future<ApiResponse> updateCourse(int id, Map<String, dynamic> data) async {
    return await _api.put('${ApiConfig.instructorCourses}/$id', body: data);
  }

  Future<ApiResponse> deleteCourse(int id) async {
    return await _api.delete('${ApiConfig.instructorCourses}/$id');
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

  Future<ApiResponse> createExam(Map<String, dynamic> data) async {
    return await _api.post(ApiConfig.instructorExams, body: data);
  }

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
