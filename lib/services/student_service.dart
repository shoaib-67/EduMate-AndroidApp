import '../config/api_config.dart';
import '../models/course.dart';
import '../models/course_content.dart';
import '../models/mock_test.dart';
import '../models/discussion.dart';
import '../models/performance.dart';
import 'api_service.dart';
import '../models/package_plan.dart';

class StudentService {
  final ApiService _api;

  StudentService(this._api);

  Future<Map<String, dynamic>?> getDashboard() async {
    final response = await _api.get(ApiConfig.studentDashboard);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<List<Course>> getCourses() async {
    final response = await _api.get(ApiConfig.studentCourses);
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

  Future<List<PackagePlan>> getPackages() async {
    final response = await _api.get(ApiConfig.packages);
    if (response.success && response.data is Map) {
      return ((response.data['packages'] as List<dynamic>?) ?? [])
          .map((p) => PackagePlan.fromJson(p as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getCourseDetails(int courseId) async {
    final response = await _api.get('${ApiConfig.studentCourses}/$courseId');
    if (response.success && response.data is Map) {
      final data = Map<String, dynamic>.from(response.data as Map);
      data['content'] = ((data['content'] as List<dynamic>?) ?? [])
          .map((item) => CourseContent.fromJson(item as Map<String, dynamic>))
          .toList();
      return data;
    }
    return null;
  }

  Future<List<MockTest>> getTests() async {
    final response = await _api.get(ApiConfig.studentTests);
    if (response.success && response.data != null) {
      final list = response.data is Map
          ? (response.data['tests'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
      return list
          .map((t) => MockTest.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<MockTest?> getTestDetails(int testId) async {
    final response = await _api.get('${ApiConfig.studentTests}/$testId');
    if (response.success && response.data != null) {
      return MockTest.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<ApiResponse> submitTest(int testId, Map<int, int> answers) async {
    return await _api.post(
      ApiConfig.studentSubmitTest,
      body: {
        'test_id': testId,
        'answers': answers.map((k, v) => MapEntry(k.toString(), v)),
      },
    );
  }

  Future<Performance?> getPerformance() async {
    final response = await _api.get(ApiConfig.studentPerformance);
    if (response.success && response.data != null) {
      return Performance.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Discussion>> getDiscussions() async {
    final response = await _api.get(ApiConfig.discussions);
    if (response.success && response.data != null) {
      final list = response.data is Map
          ? (response.data['discussions'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
      return list
          .map((d) => Discussion.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ApiResponse> createDiscussion(String title, String content) async {
    return await _api.post(
      ApiConfig.discussions,
      body: {'title': title, 'content': content},
    );
  }

  Future<ApiResponse> replyToDiscussion(int discussionId, String content) async {
    return await _api.post(
      '${ApiConfig.discussions}/$discussionId/reply',
      body: {'content': content},
    );
  }

  Future<ApiResponse> reportBug(String title, String description) async {
    return await _api.post(
      ApiConfig.studentReportBug,
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

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await _api.get(ApiConfig.studentProfile);
    if (response.success) return response.data as Map<String, dynamic>?;
    return null;
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    return await _api.put(ApiConfig.studentProfile, body: data);
  }
}
