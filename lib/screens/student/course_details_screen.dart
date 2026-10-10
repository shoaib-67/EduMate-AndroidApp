import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/course_content.dart';
import '../../providers/student_provider.dart';
import '../../utils/external_links.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class StudentCourseDetailsScreen extends StatefulWidget {
  final Course course;

  const StudentCourseDetailsScreen({super.key, required this.course});

  @override
  State<StudentCourseDetailsScreen> createState() =>
      _StudentCourseDetailsScreenState();
}

class _StudentCourseDetailsScreenState
    extends State<StudentCourseDetailsScreen> {
  List<CourseContent> _content = [];
  bool _loading = true;
  bool _loadFailed = false;
  double? _rating;
  int _ratingCount = 0;
  int? _myRating;
  bool _ratingSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final student = context.read<StudentProvider>();
    Map<String, dynamic>? details;
    try {
      final results = await Future.wait([
        student.getCourseDetails(widget.course.id!),
        student.loadTests(),
      ]);
      details = results.first as Map<String, dynamic>?;
    } catch (_) {
      details = null;
    }
    if (!mounted) return;
    setState(() {
      _content = (details?['content'] as List<CourseContent>?) ?? [];
      _rating = (details?['rating'] as num?)?.toDouble();
      _ratingCount = (details?['rating_count'] as num?)?.toInt() ?? 0;
      _myRating = (details?['my_rating'] as num?)?.toInt();
      _loadFailed = details == null;
      _loading = false;
    });
  }

  Future<void> _rateCourse(int rating) async {
    if (_ratingSaving || widget.course.id == null) return;
    setState(() => _ratingSaving = true);
    final response = await context.read<StudentProvider>().rateCourse(
      widget.course.id!,
      rating,
    );
    if (!mounted) return;
    setState(() => _ratingSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'আপনার রেটিং সংরক্ষণ করা হয়েছে'
              : response.message ?? 'রেটিং সংরক্ষণ করা যায়নি',
        ),
      ),
    );
    if (response.success) await _load();
  }

  IconData _icon(String type) {
    switch (type) {
      case 'video':
        return Icons.video_library_outlined;
      case 'exam':
        return Icons.assignment_outlined;
      case 'live':
        return Icons.videocam_outlined;
      default:
        return Icons.picture_as_pdf_outlined;
    }
  }

  String _description(CourseContent item) {
    if (item.description?.trim().isNotEmpty == true) {
      return item.description!.trim();
    }
    switch (item.type) {
      case 'video':
        return 'এই রেকর্ডেড ভিডিওটি দেখে বিষয়টি শিখুন।';
      case 'exam':
        return 'এই লিংক থেকে কোর্সের পরীক্ষা দিন।';
      case 'live':
        return 'নির্ধারিত সময়ে এই লিংক ব্যবহার করে লাইভ ক্লাসে যোগ দিন।';
      default:
        return 'এই PDF বা নোটটি পড়ে বিষয়টি প্রস্তুত করুন।';
    }
  }

  Widget _contentList(String type) {
    final items = _content.where((item) => item.type == type).toList();
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.menu_book_outlined,
        title: 'এখনও কোনো কনটেন্ট নেই',
        subtitle: 'শিক্ষক শীঘ্রই কনটেন্ট যোগ করবেন',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EduCard(
                onTap: () => openExternalUrl(item.url),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_icon(item.type), size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _description(item),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 20),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _examList() {
    final student = context.watch<StudentProvider>();
    if (student.isTestsLoading || !student.testsLoaded) {
      return const LoadingIndicator();
    }
    final exams = student.tests
        .where((test) => test.courseId == widget.course.id)
        .toList();
    final links = _content.where((item) => item.type == 'exam').toList();
    if (exams.isEmpty && links.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: student.error == null
            ? 'এখনও কোনো পরীক্ষা নেই'
            : 'পরীক্ষা লোড করা যায়নি',
        subtitle:
            student.error ??
            'শিক্ষক এই কোর্সে পরীক্ষা প্রকাশ করলে এখানে দেখা যাবে',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        for (final exam in exams)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EduCard(
              onTap: () async {
                if ((exam.attemptCount ?? 0) >= 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('এই পরীক্ষার ৩টি সুযোগ শেষ হয়েছে'),
                    ),
                  );
                  return;
                }
                final details = await context
                    .read<StudentProvider>()
                    .getTestDetails(exam.id!);
                if (!mounted) return;
                if (details == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.read<StudentProvider>().error ??
                            'পরীক্ষা খোলা যায়নি',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(context)
                    .pushNamed('/student/test', arguments: details);
              },
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${exam.subject ?? ''} · ${exam.duration ?? 0} মিনিট · ${exam.totalQuestions ?? 0} প্রশ্ন',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${exam.attemptCount ?? 0}/3 সুযোগ ব্যবহৃত',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                ],
              ),
            ),
          ),
        for (final item in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EduCard(
              onTap: () => openExternalUrl(item.url),
              padding: const EdgeInsets.all(16),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(_description(item)),
                trailing: const Icon(Icons.open_in_new),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.student,
        selectedIndex: 1,
      ),
      appBar: AppBar(
        title: Text(widget.course.title),
        actions: [
          IconButton(
            tooltip: 'কোর্স রিফ্রেশ করুন',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _loadFailed
          ? EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'কোর্স লোড করা যায়নি',
              actionText: 'আবার চেষ্টা করুন',
              onAction: _load,
            )
          : DefaultTabController(
              length: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.description ?? '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          _rating == null
                              ? 'এখনও কোনো রেটিং নেই'
                              : 'রেটিং ${_rating!.toStringAsFixed(1)}/5 ($_ratingCount)',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            tooltip: '$star তারকা রেটিং দিন',
                            visualDensity: VisualDensity.compact,
                            onPressed: _ratingSaving
                                ? null
                                : () => _rateCourse(star),
                            icon: Icon(
                              star <= (_myRating ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber.shade700,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'PDF / নোট'),
                        Tab(text: 'ভিডিও'),
                        Tab(text: 'পরীক্ষা'),
                        Tab(text: 'লাইভ ক্লাস'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _contentList('pdf'),
                          _contentList('video'),
                          _examList(),
                          _contentList('live'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
