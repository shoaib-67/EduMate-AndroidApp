import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/course_content.dart';
import '../../providers/instructor_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';
import '../student/discussion_screen.dart';
import 'instructor_exams_screen.dart';

class InstructorCourseContentScreen extends StatefulWidget {
  final Course course;

  const InstructorCourseContentScreen({super.key, required this.course});

  @override
  State<InstructorCourseContentScreen> createState() =>
      _InstructorCourseContentScreenState();
}

class _InstructorCourseContentScreenState
    extends State<InstructorCourseContentScreen>
    with SingleTickerProviderStateMixin {
  List<CourseContent> _content = [];
  bool _loading = true;
  bool _loadFailed = false;
  late final TabController _tabController;
  late Future<List<Map<String, dynamic>>> _exams;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this)
      ..addListener(() => setState(() {}));
    _reloadExams();
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reloadExams() {
    _exams = context.read<InstructorProvider>().getCourseExams(
      widget.course.id!,
    );
  }

  Future<void> _openExams({bool create = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InstructorExamsScreen(
          course: widget.course,
          openCreateOnLoad: create,
        ),
      ),
    );
    if (!mounted) return;
    setState(_reloadExams);
    context.read<InstructorProvider>().loadDashboard();
  }

  Future<void> _loadContent() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    List<CourseContent> items = [];
    bool failed = false;
    try {
      items = await context.read<InstructorProvider>().getCourseContent(
        widget.course.id!,
      );
    } catch (_) {
      failed = true;
    }
    if (mounted) {
      setState(() {
        _content = items;
        _loadFailed = failed;
        _loading = false;
      });
    }
  }

  Future<void> _addContent() async {
    final title = TextEditingController();
    final url = TextEditingController();
    final description = TextEditingController();
    var type = 'pdf';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('কোর্স কনটেন্ট যোগ করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'শিরোনাম'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'ধরন'),
                  items: const [
                    DropdownMenuItem(value: 'pdf', child: Text('PDF / নোট')),
                    DropdownMenuItem(
                      value: 'video',
                      child: Text('রেকর্ডেড ভিডিও'),
                    ),
                    DropdownMenuItem(value: 'live', child: Text('লাইভ ক্লাস')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? 'pdf'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'লিংক (PDF/ভিডিও/লাইভ ক্লাস)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'সংক্ষিপ্ত বিবরণ',
                    hintText: 'শিক্ষার্থীরা এই কনটেন্ট সম্পর্কে কী জানবে?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty ||
                    url.text.trim().isEmpty ||
                    description.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('শিরোনাম, লিংক ও বিবরণ পূরণ করুন।'),
                    ),
                  );
                  return;
                }
                final ok = await context
                    .read<InstructorProvider>()
                    .addCourseContent(widget.course.id!, {
                      'title': title.text.trim(),
                      'type': type,
                      'url': url.text.trim(),
                      'description': description.text.trim(),
                    });
                if (ctx.mounted) {
                  if (ok) {
                    Navigator.pop(ctx, true);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'কনটেন্ট যোগ করা যায়নি। আবার চেষ্টা করুন।',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('যোগ করুন'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    url.dispose();
    description.dispose();
    if (result == true) _loadContent();
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

  Widget _examTab() {
    final links = _content.where((item) => item.type == 'exam').toList();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _exams,
      builder: (context, snapshot) {
        final exams = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FilledButton.icon(
              onPressed: () => _openExams(create: true),
              icon: const Icon(Icons.add_rounded),
              label: const Text('নতুন পরীক্ষা তৈরি করুন'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openExams(),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('পরীক্ষা পরিচালনা করুন'),
            ),
            const SizedBox(height: 24),
            if (snapshot.connectionState != ConnectionState.done)
              const LoadingIndicator()
            else if (snapshot.hasError) ...[
              const Text('পরীক্ষা লোড করা যায়নি'),
              TextButton.icon(
                onPressed: () => setState(_reloadExams),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ] else if (exams.isEmpty && links.isEmpty)
              const EmptyState(
                icon: Icons.assignment_outlined,
                title: 'এখনও কোনো পরীক্ষা নেই',
                subtitle: 'উপরে পরীক্ষা তৈরি করুন চাপ দিয়ে MCQ যোগ করুন',
              )
            else ...[
              for (final exam in exams)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EduCard(
                    onTap: () => _openExams(),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.assignment_outlined,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${exam['title']}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                exam['published'] == 1 ||
                                        exam['published'] == true
                                    ? 'প্রকাশিত'
                                    : 'লুকানো',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              if (links.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'পরীক্ষার লিংক',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                for (final link in links)
                  ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: Text(link.title),
                    subtitle: Text(link.description ?? ''),
                    onTap: () => openExternalUrl(link.url),
                    trailing: IconButton(
                      tooltip: 'পরীক্ষার লিংক মুছুন',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteContent(link),
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _deleteContent(CourseContent item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('কনটেন্ট মুছবেন?'),
        content: Text('“${item.title}” মুছে ফেলা হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await context.read<InstructorProvider>().deleteCourseContent(
      widget.course.id!,
      item.id,
    );
    if (ok && mounted) _loadContent();
  }

  Widget _contentList(String type) {
    final items = _content.where((item) => item.type == type).toList();
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.library_add_outlined,
        title: 'কোনো কনটেন্ট নেই',
        subtitle: 'উপরে + চাপ দিয়ে কনটেন্ট যোগ করুন',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EduCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(_icon(item.type), color: AppTheme.primaryColor, size: 28),
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
                        item.description ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'লিংক খুলুন',
                  onPressed: () => openExternalUrl(item.url),
                  icon: const Icon(Icons.open_in_new),
                ),
                IconButton(
                  tooltip: 'কনটেন্ট মুছুন',
                  onPressed: () => _deleteContent(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.instructor,
        selectedIndex: 1,
      ),
      appBar: AppBar(
        title: Text(widget.course.title),
        actions: [
          IconButton(
            tooltip: 'কনটেন্ট রিফ্রেশ করুন',
            onPressed: _loading
                ? null
                : () {
                    _loadContent();
                    setState(_reloadExams);
                  },
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_tabController.index != 3)
            IconButton(
              tooltip: _tabController.index == 4
                  ? 'পরীক্ষা তৈরি করুন'
                  : 'কনটেন্ট যোগ করুন',
              onPressed: _tabController.index == 4
                  ? () => _openExams(create: true)
                  : _addContent,
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _loadFailed
          ? EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'কনটেন্ট লোড করা যায়নি',
              actionText: 'আবার চেষ্টা করুন',
              onAction: _loadContent,
            )
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'PDF / নোট'),
                    Tab(text: 'ভিডিও'),
                    Tab(text: 'লাইভ ক্লাস'),
                    Tab(text: 'আলোচনা'),
                    Tab(text: 'পরীক্ষা'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _contentList('pdf'),
                      _contentList('video'),
                      _contentList('live'),
                      DiscussionScreen(
                        courseId: widget.course.id!,
                        isInstructor: true,
                        embedded: true,
                      ),
                      _examTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
