class Question {
  final int? id;
  final String questionText;
  final List<String> options;
  final int? correctOption; // Answer key is only returned to administrators.
  final List<int>? optionOrder;
  final String? explanation;
  final String? subject;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    this.correctOption,
    this.optionOrder,
    this.explanation,
    this.subject,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int?,
      questionText: json['question_text'] as String? ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctOption: json['correct_option'] as int?,
      optionOrder: (json['option_order'] as List<dynamic>?)
          ?.map((value) => (value as num).toInt())
          .toList(),
      explanation: json['explanation'] as String?,
      subject: json['subject'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question_text': questionText,
      'options': options,
      'correct_option': correctOption,
      'explanation': explanation,
      'subject': subject,
    };
  }
}

class MockTest {
  static num? _number(dynamic value) => value is num
      ? value
      : value is String
      ? num.tryParse(value)
      : null;

  final int? id;
  final String title;
  final String? description;
  final String? subject;
  final int? duration; // in minutes
  final int? totalQuestions;
  final num? totalMarks;
  final int? courseId;
  final String? courseTitle;
  final num? perMcqMark;
  final num? negativeMarking;
  final List<Question>? questions;
  final bool? isCompleted;
  final int? attemptCount;
  final DateTime? scheduledAt;
  final DateTime? createdAt;

  MockTest({
    this.id,
    required this.title,
    this.description,
    this.subject,
    this.duration,
    this.totalQuestions,
    this.totalMarks,
    this.courseId,
    this.courseTitle,
    this.perMcqMark,
    this.negativeMarking,
    this.questions,
    this.isCompleted,
    this.attemptCount,
    this.scheduledAt,
    this.createdAt,
  });

  factory MockTest.fromJson(Map<String, dynamic> json) {
    return MockTest(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      subject: json['subject'] as String?,
      duration: json['duration'] as int?,
      totalQuestions: json['total_questions'] as int?,
      totalMarks: _number(json['total_marks']),
      courseId: json['course_id'] as int?,
      courseTitle: json['course_title'] as String?,
      perMcqMark: _number(json['per_mcq_mark']),
      negativeMarking: _number(json['negative_marking']),
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      attemptCount: (json['attempt_count'] as num?)?.toInt(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'duration': duration,
      'total_questions': totalQuestions,
      'total_marks': totalMarks,
      'questions': questions?.map((q) => q.toJson()).toList(),
    };
  }
}
