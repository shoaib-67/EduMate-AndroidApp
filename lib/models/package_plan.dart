class PackagePlan {
  final int id;
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final List<String> features;

  PackagePlan({required this.id, required this.title, required this.subtitle, required this.price, required this.period, required this.features});

  factory PackagePlan.fromJson(Map<String, dynamic> json) => PackagePlan(
    id: (json['id'] as num?)?.toInt() ?? 0,
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    price: json['price'] as String? ?? '',
    period: json['period'] as String? ?? '',
    features: (json['features'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
  );
}
