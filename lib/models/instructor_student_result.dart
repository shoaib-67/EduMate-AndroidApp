class InstructorStudentResult {
  const InstructorStudentResult({
    required this.id,
    required this.name,
    required this.email,
    required this.enrolledCourses,
    required this.testsCompleted,
    this.averageScore,
  });

  final int id;
  final String name;
  final String email;
  final int enrolledCourses;
  final int testsCompleted;
  final double? averageScore;

  factory InstructorStudentResult.fromJson(Map<String, dynamic> json) {
    final attempts = _asInt(json['tests_completed']);
    return InstructorStudentResult(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      enrolledCourses: _asInt(json['enrolled_courses']),
      testsCompleted: attempts,
      averageScore: attempts == 0 ? null : _asDouble(json['average_score']),
    );
  }
}

class InstructorExamResult {
  const InstructorExamResult({
    required this.courseTitle,
    required this.examTitle,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.completedAt,
  });

  final String courseTitle;
  final String examTitle;
  final double score;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime? completedAt;

  factory InstructorExamResult.fromJson(Map<String, dynamic> json) {
    return InstructorExamResult(
      courseTitle: json['course_title'] as String? ?? '',
      examTitle: json['exam_title'] as String? ?? '',
      score: _asDouble(json['score']) ?? 0,
      correctAnswers: _asInt(json['correct_answers']),
      totalQuestions: _asInt(json['total_questions']),
      completedAt: DateTime.tryParse(json['completed_at']?.toString() ?? ''),
    );
  }
}

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

double? _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
