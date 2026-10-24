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
    if (!response.success) {
      throw Exception(response.message ?? 'প্যাকেজ লোড করা যায়নি');
    }
    if (response.data is Map) {
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

  Future<ApiResponse> rateCourse(int courseId, int rating) {
    return _api.post(
      '${ApiConfig.studentCourses}/$courseId/rating',
      body: {'rating': rating},
    );
  }

  Future<List<MockTest>> getTests() async {
    final response = await _api.get(ApiConfig.studentTests);
    if (!response.success) {
      throw StudentExamException(response.message ?? 'Could not load exams');
    }
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
    if (!response.success) {
      throw StudentExamException(response.message ?? 'Could not open exam');
    }
    if (response.success && response.data != null) {
      return MockTest.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<ApiResponse> submitTest(
    int testId,
    Map<int, dynamic> answers, {
    String? submissionId,
    String reason = 'manual',
  }) async {
    return await _api.post(
      ApiConfig.studentSubmitTest,
      body: {
        'test_id': testId,
        'submission_id': ?submissionId,
        'submission_reason': reason,
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

  Future<List<Discussion>> getDiscussions({int? courseId}) async {
    final response = await _api.get(
      ApiConfig.discussions,
      queryParams: courseId == null ? null : {'course_id': '$courseId'},
    );
    if (response.success && response.data != null) {
      final list = response.data is Map
          ? (response.data['discussions'] as List<dynamic>? ?? [])
          : (response.data as List<dynamic>);
      return list
          .map((d) => Discussion.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    throw Exception(response.message ?? 'আলোচনা লোড করা যায়নি');
  }

  Future<Discussion?> getDiscussion(int id) async {
    final response = await _api.get('${ApiConfig.discussions}/$id');
    if (response.success && response.data is Map<String, dynamic>) {
      return Discussion.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<ApiResponse> createDiscussion(
    String title,
    String content, {
    int? courseId,
  }) async {
    final body = <String, dynamic>{'title': title, 'content': content};
    if (courseId != null) body['course_id'] = courseId;
    return await _api.post(ApiConfig.discussions, body: body);
  }

  Future<ApiResponse> replyToDiscussion(
    int discussionId,
    String content,
  ) async {
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
}

class StudentExamException implements Exception {
  final String message;

  const StudentExamException(this.message);

  @override
  String toString() => message;
}
