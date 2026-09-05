import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/course_content.dart';
import '../../providers/student_provider.dart';
import '../../utils/external_links.dart';
import '../../widgets/common_widgets.dart';

class StudentCourseDetailsScreen extends StatefulWidget {
  final Course course;

  const StudentCourseDetailsScreen({super.key, required this.course});

  @override
  State<StudentCourseDetailsScreen> createState() =>
      _StudentCourseDetailsScreenState();
}

class _StudentCourseDetailsScreenState extends State<StudentCourseDetailsScreen> {
  List<CourseContent> _content = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    context.read<StudentProvider>().getCourseDetails(widget.course.id!).then((data) {
      if (!mounted) return;
      setState(() {
        _content = (data?['content'] as List<CourseContent>?) ?? [];
        _loading = false;
      });
    });
  }

  IconData _icon(String type) {
    switch (type) {
      case 'video': return Icons.video_library_outlined;
      case 'exam': return Icons.assignment_outlined;
      case 'live': return Icons.videocam_outlined;
      default: return Icons.picture_as_pdf_outlined;
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
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: EduCard(
          onTap: () => openExternalUrl(item.url),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(_icon(item.type), size: 28),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: Theme.of(context).textTheme.titleMedium),
              Text(_description(item), maxLines: 3, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ])),
            const Icon(Icons.open_in_new, size: 20),
          ]),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.title)),
      body: _loading
          ? const LoadingIndicator()
          : DefaultTabController(
              length: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.course.description ?? '', style: Theme.of(context).textTheme.bodyLarge),
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
                  Expanded(child: TabBarView(children: [_contentList('pdf'), _contentList('video'), _contentList('exam'), _contentList('live')])),
                ],
                ),
              ),
            ),
    );
  }
}
