class Question {
  final int? id;
  final String questionText;
  final List<String> options;
  final int correctOption; // 0-indexed
  final String? explanation;
  final String? subject;

  Question({
    this.id,
    required this.questionText,
    required this.options,
    required this.correctOption,
    this.explanation,
    this.subject,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int?,
      questionText: json['question_text'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      correctOption: json['correct_option'] as int? ?? 0,
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
  final int? id;
  final String title;
  final String? description;
  final String? subject;
  final int? duration; // in minutes
  final int? totalQuestions;
  final int? totalMarks;
  final List<Question>? questions;
  final bool? isCompleted;
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
    this.questions,
    this.isCompleted,
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
      totalMarks: json['total_marks'] as int?,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(),
      isCompleted: json['is_completed'] as bool?,
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
