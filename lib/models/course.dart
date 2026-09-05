class Course {
  final int? id;
  final String title;
  final String? description;
  final String? category;
  final String? thumbnail;
  final String? instructorName;
  final int? instructorId;
  final int? totalLessons;
  final int? enrolledCount;
  final double? rating;
  final bool? isPremium;
  final DateTime? createdAt;

  Course({
    this.id,
    required this.title,
    this.description,
    this.category,
    this.thumbnail,
    this.instructorName,
    this.instructorId,
    this.totalLessons,
    this.enrolledCount,
    this.rating,
    this.isPremium,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      category: json['category'] as String?,
      thumbnail: json['thumbnail'] as String?,
      instructorName: json['instructor_name'] as String?,
      instructorId: json['instructor_id'] as int?,
      totalLessons: json['total_lessons'] as int?,
      enrolledCount: json['enrolled_count'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      // MySQL serializes BOOLEAN/FALSE values as 0/1 in the API response.
      isPremium: json['is_premium'] == true ||
          json['is_premium'] == 1 ||
          json['is_premium'] == '1',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'thumbnail': thumbnail,
      'instructor_id': instructorId,
      'total_lessons': totalLessons,
      'is_premium': isPremium,
    };
  }
}
