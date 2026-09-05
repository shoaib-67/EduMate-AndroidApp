class CourseContent {
  final int id;
  final String title;
  final String type;
  final String url;
  final String? description;

  CourseContent({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    this.description,
  });

  factory CourseContent.fromJson(Map<String, dynamic> json) {
    return CourseContent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'pdf',
      url: json['url'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}
