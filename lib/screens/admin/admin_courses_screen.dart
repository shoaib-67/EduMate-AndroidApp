import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminCoursesScreen extends StatefulWidget {
  const AdminCoursesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AdminCoursesScreen> createState() => _AdminCoursesScreenState();
}

class _AdminCoursesScreenState extends State<AdminCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminProvider>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Expanded(
                child: Text(
                  'কোর্সসমূহ',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                onPressed: () => _showCourseDialog(),
                icon: const Icon(Icons.add_circle_rounded),
                tooltip: 'নতুন কোর্স যোগ করুন',
              ),
            ],
          ),
        ),
        Expanded(
          child: admin.isCoursesLoading || !admin.coursesLoaded
              ? const LoadingIndicator()
              : admin.coursesError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(admin.coursesError!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: admin.loadCourses,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('আবার চেষ্টা করুন'),
                      ),
                    ],
                  ),
                )
              : admin.courses.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'কোনো কোর্স নেই',
                  subtitle: 'উপরের যোগ বোতাম থেকে নতুন কোর্স তৈরি করুন',
                )
              : RefreshIndicator(
                  onRefresh: admin.loadCourses,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: admin.courses.length,
                    itemBuilder: (context, index) =>
                        _courseCard(admin.courses[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _courseCard(Course course) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: EduCard(
        onTap: () => _showCourseDialog(course: course),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'ইনস্ট্রাক্টর: ${course.instructorName ?? 'নির্ধারিত নেই'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${course.enrolledCount ?? 0} শিক্ষার্থী',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (course.description?.isNotEmpty == true)
                    Text(
                      course.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showStudentsDialog(course),
              icon: const Icon(Icons.group_add_outlined),
              tooltip: 'শিক্ষার্থী যোগ বা সরান',
            ),
            PopupMenuButton<String>(
              tooltip: 'কোর্সের কাজ',
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                PopupMenuItem(value: 'delete', child: Text('মুছুন')),
              ],
              onSelected: (action) {
                if (action == 'edit') {
                  _showCourseDialog(course: course);
                } else {
                  _deleteCourse(course);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStudentsDialog(Course course) async {
    if (course.id == null) return;
    final admin = context.read<AdminProvider>();
    var studentsFuture = admin.getCourseStudents(course.id!);
    int? pendingStudentId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('${course.title} — শিক্ষার্থী'),
          content: SizedBox(
            width: 460,
            height: MediaQuery.sizeOf(dialogContext).height * 0.55,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: studentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => setDialogState(() {
                            studentsFuture = admin.getCourseStudents(
                              course.id!,
                            );
                          }),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('আবার চেষ্টা করুন'),
                        ),
                      ],
                    ),
                  );
                }
                final students = snapshot.data ?? [];
                if (students.isEmpty) {
                  return const Center(
                    child: Text(
                      'প্রথমে ব্যবহারকারী বিভাগে শিক্ষার্থী যোগ করুন',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final id = student['id'] as int;
                    final enrolled =
                        student['is_enrolled'] == 1 ||
                        student['is_enrolled'] == true;
                    return CheckboxListTile(
                      value: enrolled,
                      title: Text(student['name'] as String? ?? ''),
                      subtitle: Text(student['email'] as String? ?? ''),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: pendingStudentId != null
                          ? null
                          : (selected) async {
                              setDialogState(() => pendingStudentId = id);
                              final response = selected == true
                                  ? await admin.addStudentToCourse(
                                      course.id!,
                                      id,
                                    )
                                  : await admin.removeStudentFromCourse(
                                      course.id!,
                                      id,
                                    );
                              if (!dialogContext.mounted) return;
                              if (response.success) {
                                setDialogState(() {
                                  studentsFuture = admin.getCourseStudents(
                                    course.id!,
                                  );
                                  pendingStudentId = null;
                                });
                              } else {
                                setDialogState(() => pendingStudentId = null);
                                ScaffoldMessenger.of(dialogContext)
                                    .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          response.message ??
                                              'শিক্ষার্থী আপডেট করা যায়নি',
                                        ),
                                      ),
                                    );
                              }
                            },
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: pendingStudentId == null
                  ? () => Navigator.pop(dialogContext)
                  : null,
              child: const Text('বন্ধ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCourseDialog({Course? course}) async {
    final admin = context.read<AdminProvider>();
    await admin.loadUsers();
    if (!mounted) return;
    if (admin.usersError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(admin.usersError!)));
      return;
    }
    final instructors = admin.users
        .where((user) => user.role == 'instructor' && user.id != null)
        .toList();
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: course?.title);
    final descCtrl = TextEditingController(text: course?.description);
    int? instructorId =
        instructors.any((user) => user.id == course?.instructorId)
        ? course?.instructorId
        : null;
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(course == null ? 'নতুন কোর্স তৈরি' : 'কোর্স সম্পাদনা'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleCtrl,
                      maxLength: 180,
                      decoration: const InputDecoration(
                        labelText: 'কোর্সের নাম *',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'কোর্সের নাম লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'বিবরণ',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: instructorId,
                      decoration: const InputDecoration(
                        labelText: 'ইনস্ট্রাক্টর',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          child: Text('পরে নির্ধারণ করুন'),
                        ),
                        for (final instructor in instructors)
                          DropdownMenuItem(
                            value: instructor.id,
                            child: Text(instructor.name),
                          ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) =>
                                setDialogState(() => instructorId = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('বাতিল'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      final data = {
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'instructor_id': instructorId,
                      };
                      final response = course == null
                          ? await admin.createCourse(data)
                          : await admin.updateCourse(course.id!, data);
                      if (!dialogContext.mounted) return;
                      if (response.success) {
                        Navigator.pop(dialogContext);
                      } else {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              response.message ?? 'কোর্স সংরক্ষণ করা যায়নি',
                            ),
                          ),
                        );
                      }
                    },
              icon: Icon(
                course == null ? Icons.add_rounded : Icons.save_outlined,
              ),
              label: Text(course == null ? 'তৈরি করুন' : 'সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _deleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('কোর্স মুছবেন?'),
        content: Text('"${course.title}" এবং এর সব কনটেন্ট মুছে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('মুছুন'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || course.id == null) return;
    final response = await context.read<AdminProvider>().deleteCourse(
      course.id!,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'কোর্স মুছে ফেলা যায়নি')),
    );
  }
}
