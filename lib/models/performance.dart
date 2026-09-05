class Performance {
  final double? averageScore;
  final int? totalTestsTaken;
  final int? totalCorrect;
  final int? totalIncorrect;
  final int? rank;
  final int? totalParticipants;
  final List<SubjectPerformance>? subjectWise;
  final List<TestResult>? recentResults;

  Performance({
    this.averageScore,
    this.totalTestsTaken,
    this.totalCorrect,
    this.totalIncorrect,
    this.rank,
    this.totalParticipants,
    this.subjectWise,
    this.recentResults,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      averageScore: (json['average_score'] as num?)?.toDouble(),
      totalTestsTaken: json['total_tests_taken'] as int?,
      totalCorrect: json['total_correct'] as int?,
      totalIncorrect: json['total_incorrect'] as int?,
      rank: json['rank'] as int?,
      totalParticipants: json['total_participants'] as int?,
      subjectWise: (json['subject_wise'] as List<dynamic>?)
          ?.map(
              (s) => SubjectPerformance.fromJson(s as Map<String, dynamic>))
          .toList(),
      recentResults: (json['recent_results'] as List<dynamic>?)
          ?.map((r) => TestResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectPerformance {
  final String subject;
  final double score;
  final int totalQuestions;
  final int correctAnswers;

  SubjectPerformance({
    required this.subject,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) {
    return SubjectPerformance(
      subject: json['subject'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      correctAnswers: json['correct_answers'] as int? ?? 0,
    );
  }
}

class TestResult {
  final int? id;
  final String? testTitle;
  final double? score;
  final int? totalMarks;
  final int? correctAnswers;
  final int? totalQuestions;
  final int? rank;
  final DateTime? completedAt;

  TestResult({
    this.id,
    this.testTitle,
    this.score,
    this.totalMarks,
    this.correctAnswers,
    this.totalQuestions,
    this.rank,
    this.completedAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] as int?,
      testTitle: json['test_title'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      totalMarks: json['total_marks'] as int?,
      correctAnswers: json['correct_answers'] as int?,
      totalQuestions: json['total_questions'] as int?,
      rank: json['rank'] as int?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
    );
  }
}
