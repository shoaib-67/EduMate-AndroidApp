class PackagePlan {
  final int id;
  final int? courseId;
  final String courseTitle;
  final bool hasAccess;
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final List<String> features;

  PackagePlan({
    required this.id,
    this.courseId,
    this.courseTitle = '',
    this.hasAccess = false,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.features,
  });

  factory PackagePlan.fromJson(Map<String, dynamic> json) => PackagePlan(
    id: (json['id'] as num?)?.toInt() ?? 0,
    courseId: (json['course_id'] as num?)?.toInt(),
    courseTitle: json['course_title'] as String? ?? '',
    hasAccess: json['has_access'] == true || json['has_access'] == 1,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    price: json['price'] as String? ?? '',
    period: json['period'] as String? ?? '',
    features: (json['features'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}
