import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../models/course_content.dart';
import '../../providers/instructor_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/external_links.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class InstructorCourseContentScreen extends StatefulWidget {
  final Course course;

  const InstructorCourseContentScreen({super.key, required this.course});

  @override
  State<InstructorCourseContentScreen> createState() =>
      _InstructorCourseContentScreenState();
}

class _InstructorCourseContentScreenState
    extends State<InstructorCourseContentScreen> {
  List<CourseContent> _content = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
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
                    DropdownMenuItem(value: 'exam', child: Text('পরীক্ষা')),
                    DropdownMenuItem(value: 'live', child: Text('লাইভ ক্লাস')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? 'pdf'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  decoration: const InputDecoration(
                    labelText: 'লিংক (PDF/ভিডিও/পরীক্ষা/লাইভ ক্লাস)',
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
                  onPressed: () async {
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
                    if (confirmed != true || !context.mounted) return;
                    final ok = await context
                        .read<InstructorProvider>()
                        .deleteCourseContent(widget.course.id!, item.id);
                    if (ok && mounted) _loadContent();
                  },
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
            onPressed: _loading ? null : _loadContent,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'কনটেন্ট যোগ করুন',
            onPressed: _addContent,
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
          : DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'PDF / নোট'),
                      Tab(text: 'ভিডিও'),
                      Tab(text: 'পরীক্ষা'),
                      Tab(text: 'লাইভ ক্লাস'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _contentList('pdf'),
                        _contentList('video'),
                        _contentList('exam'),
                        _contentList('live'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
