import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../providers/instructor_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class InstructorExamCoursePickerScreen extends StatefulWidget {
  const InstructorExamCoursePickerScreen({super.key});

  @override
  State<InstructorExamCoursePickerScreen> createState() =>
      _InstructorExamCoursePickerScreenState();
}

class _InstructorExamCoursePickerScreenState
    extends State<InstructorExamCoursePickerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InstructorProvider>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final instructor = context.watch<InstructorProvider>();
    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.instructor,
        selectedIndex: 1,
      ),
      appBar: AppBar(title: const Text('পরীক্ষা তৈরি করুন')),
      body: instructor.isCoursesLoading || !instructor.coursesLoaded
          ? const LoadingIndicator()
          : instructor.courses.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'কোনো কোর্স নেই',
              subtitle: 'আপনাকে কোর্সে শিক্ষক হিসেবে অ্যাসাইন করতে হবে',
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: RefreshIndicator(
                  onRefresh: context.read<InstructorProvider>().loadCourses,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'একটি কোর্স নির্বাচন করুন',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'এই কোর্সে ভর্তি শিক্ষার্থীরা আপনার পরীক্ষা দেখতে পারবে।',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      for (final course in instructor.courses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EduCard(
                            onTap: course.id == null
                                ? null
                                : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InstructorExamsScreen(
                                        course: course,
                                        openCreateOnLoad: true,
                                      ),
                                    ),
                                  ),
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        course.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${course.enrolledCount ?? 0} জন ভর্তি শিক্ষার্থী',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: AppTheme.textMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class InstructorExamsScreen extends StatefulWidget {
  const InstructorExamsScreen({
    super.key,
    required this.course,
    this.openCreateOnLoad = false,
  });

  final Course course;
  final bool openCreateOnLoad;

  @override
  State<InstructorExamsScreen> createState() => _InstructorExamsScreenState();
}

class _InstructorExamsScreenState extends State<InstructorExamsScreen> {
  late Future<List<Map<String, dynamic>>> _exams;

  @override
  void initState() {
    super.initState();
    _reload();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openEditor();
      });
    }
  }

  void _reload() {
    _exams = context.read<InstructorProvider>().getCourseExams(
      widget.course.id!,
    );
  }

  Future<void> _openEditor([int? examId]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ExamEditor(course: widget.course, examId: examId),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _toggle(Map<String, dynamic> exam) async {
    final published = exam['published'] == 1 || exam['published'] == true;
    final response = await context.read<InstructorProvider>().publishExam(
      exam['id'] as int,
      !published,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'পরীক্ষা আপডেট করা যায়নি')),
    );
    if (response.success) setState(_reload);
  }

  Future<void> _delete(Map<String, dynamic> exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পরীক্ষা মুছে ফেলবেন?'),
        content: Text('“${exam['title']}” এবং এর সব প্রশ্ন মুছে ফেলবেন?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছে ফেলুন'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final response = await context.read<InstructorProvider>().deleteExam(
      exam['id'] as int,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'পরীক্ষা মুছে ফেলা যায়নি')),
    );
    if (response.success) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const RoleBottomNavigation(
      role: AppRole.instructor,
      selectedIndex: 1,
    ),
    appBar: AppBar(title: const Text('পরীক্ষা পরিচালনা')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _exams,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${snapshot.error}', textAlign: TextAlign.center),
                OutlinedButton(
                  onPressed: () => setState(_reload),
                  child: const Text('আবার চেষ্টা করুন'),
                ),
              ],
            ),
          );
        }
        final exams = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: () async {
                setState(_reload);
                await _exams;
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.course.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'প্রকাশ করার সঙ্গে সঙ্গে শিক্ষার্থীরা পরীক্ষা দিতে পারবে।',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('নতুন পরীক্ষা তৈরি করুন'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'আপনার পরীক্ষাগুলো',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(
                        '${exams.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (exams.isEmpty)
                    const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'এখনও কোনো পরীক্ষা নেই',
                      subtitle:
                          'এই কোর্সের জন্য একটি পরীক্ষা তৈরি করে MCQ যোগ করুন।',
                    ),
                  for (final exam in exams)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EduCard(
                        onTap: (exam['attempt_count'] as num? ?? 0) > 0
                            ? null
                            : () => _openEditor(exam['id'] as int),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${exam['title']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'পরীক্ষার কাজ',
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      enabled:
                                          (exam['attempt_count'] as num? ??
                                              0) ==
                                          0,
                                      child: const Text('পরীক্ষা সম্পাদনা'),
                                    ),
                                    PopupMenuItem(
                                      value: 'visibility',
                                      child: Text(
                                        _isPublished(exam)
                                            ? 'শিক্ষার্থীদের কাছ থেকে লুকান'
                                            : 'শিক্ষার্থীদের জন্য প্রকাশ করুন',
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      enabled:
                                          (exam['attempt_count'] as num? ??
                                              0) ==
                                          0,
                                      child: const Text('পরীক্ষা মুছে ফেলুন'),
                                    ),
                                  ],
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _openEditor(exam['id'] as int);
                                    }
                                    if (action == 'visibility') _toggle(exam);
                                    if (action == 'delete') _delete(exam);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaChip(
                                  icon: Icons.topic_outlined,
                                  text: '${exam['subject'] ?? 'সাধারণ'}',
                                ),
                                _MetaChip(
                                  icon: Icons.timer_outlined,
                                  text: '${exam['duration']} মিনিট',
                                ),
                                _MetaChip(
                                  icon: Icons.help_outline,
                                  text: '${exam['total_questions']}টি প্রশ্ন',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  _isPublished(exam)
                                      ? Icons.check_circle_rounded
                                      : Icons.visibility_off_outlined,
                                  size: 16,
                                  color: _isPublished(exam)
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isPublished(exam) ? 'প্রকাশিত' : 'লুকানো',
                                  style: TextStyle(
                                    color: _isPublished(exam)
                                        ? AppTheme.success
                                        : AppTheme.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                if ((exam['attempt_count'] as num? ?? 0) > 0)
                                  Text(
                                    '${exam['attempt_count']} বার চেষ্টা',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  bool _isPublished(Map<String, dynamic> exam) =>
      exam['published'] == 1 || exam['published'] == true;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppTheme.primaryLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 5),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppTheme.primaryColor),
        ),
      ],
    ),
  );
}

class _ExamEditor extends StatefulWidget {
  const _ExamEditor({required this.course, this.examId});
  final Course course;
  final int? examId;

  @override
  State<_ExamEditor> createState() => _ExamEditorState();
}

class _ExamEditorState extends State<_ExamEditor> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _duration = TextEditingController(text: '30');
  final _perMark = TextEditingController(text: '1');
  final _negative = TextEditingController(text: '0');
  final _rules = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  String _shuffle = 'none';
  int _step = 0;
  bool _busy = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.examId != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final exam = await context.read<InstructorProvider>().getExam(
        widget.examId!,
      );
      if (!mounted) return;
      _title.text = '${exam['title'] ?? ''}';
      _subject.text = '${exam['subject'] ?? ''}';
      _duration.text = '${exam['duration'] ?? 30}';
      _perMark.text = '${exam['per_mcq_mark'] ?? 1}';
      _negative.text = '${exam['negative_marking'] ?? 0}';
      _rules.text = '${exam['description'] ?? ''}';
      setState(() {
        _shuffle = '${exam['shuffle_mode'] ?? 'none'}';
        _questions.addAll(
          (exam['questions'] as List<dynamic>).map(
            (q) => Map<String, dynamic>.from(q as Map),
          ),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final ctrl in [
      _title,
      _subject,
      _duration,
      _perMark,
      _negative,
      _rules,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'এই ঘরটি পূরণ করুন' : null;

  String? _durationError(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    return minutes == null || minutes < 5 || minutes > 60
        ? '৫ থেকে ৬০ মিনিটের মধ্যে লিখুন'
        : null;
  }

  String? _markError(String? value) {
    final mark = double.tryParse(value?.trim() ?? '');
    return mark == null || mark <= 0 || mark > 100
        ? '০-এর বেশি এবং ১০০-এর মধ্যে নম্বর লিখুন'
        : null;
  }

  String? _negativeError(String? value) {
    final negative = double.tryParse(value?.trim() ?? '');
    final mark = double.tryParse(_perMark.text.trim());
    return negative == null || negative < 0 || mark == null || negative >= mark
        ? '০ অথবা MCQ নম্বরের চেয়ে কম একটি মান লিখুন'
        : null;
  }

  void _nextStep() {
    if (_step == 0 && !_form.currentState!.validate()) return;
    if (_step == 1 && _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('চালিয়ে যেতে অন্তত একটি প্রশ্ন যোগ করুন'),
        ),
      );
      return;
    }
    if (_step < 2) setState(() => _step++);
  }

  Future<void> _editQuestion([int? index]) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _QuestionEditorScreen(
          question: index == null ? null : _questions[index],
          number: (index ?? _questions.length) + 1,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (index == null) {
          _questions.add(result);
        } else {
          _questions[index] = result;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      setState(() => _step = 0);
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('অন্তত একটি MCQ যোগ করুন')));
      return;
    }
    final duration = int.tryParse(_duration.text.trim());
    final perMark = double.tryParse(_perMark.text.trim());
    final negative = double.tryParse(_negative.text.trim());
    if (duration == null || perMark == null || negative == null) return;
    setState(() => _busy = true);
    final data = {
      'title': _title.text.trim(),
      'subject': _subject.text.trim(),
      'description': _rules.text.trim(),
      'duration': duration,
      'per_mcq_mark': perMark,
      'negative_marking': negative,
      'shuffle_mode': _shuffle,
      'questions': _questions,
    };
    final instructor = context.read<InstructorProvider>();
    final response = widget.examId == null
        ? await instructor.createExam(widget.course.id!, data)
        : await instructor.updateExam(widget.examId!, data);
    if (!mounted) return;
    setState(() => _busy = false);
    if (response.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'পরীক্ষা সংরক্ষণ করা যায়নি'),
        ),
      );
    }
  }

  Widget _page(List<Widget> children) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: children,
      ),
    ),
  );

  Widget _intro(BuildContext context, String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineLarge),
      const SizedBox(height: 6),
      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 22),
    ],
  );

  Widget _detailsStep(BuildContext context) => _page([
    _intro(
      context,
      'পরীক্ষার তথ্য',
      '${widget.course.title}-এর তথ্য পূরণ করুন।',
    ),
    EduCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('প্রাথমিক তথ্য', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'পরীক্ষার শিরোনাম',
              hintText: 'যেমন: পদার্থবিজ্ঞান সাপ্তাহিক মডেল টেস্ট',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            validator: (value) {
              if (_required(value) != null) return 'পরীক্ষার শিরোনাম লিখুন';
              return value!.trim().length > 180
                  ? '১৮০টি বা তার কম অক্ষর ব্যবহার করুন'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _subject,
            decoration: const InputDecoration(
              labelText: 'বিষয়',
              hintText: 'যেমন: পদার্থবিজ্ঞান',
              prefixIcon: Icon(Icons.topic_outlined),
            ),
            validator: (value) {
              if (_required(value) != null) return 'বিষয় লিখুন';
              return value!.trim().length > 120
                  ? '১২০টি বা তার কম অক্ষর ব্যবহার করুন'
                  : null;
            },
          ),
          const SizedBox(height: 24),
          Text('সময় ও নম্বর', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _duration,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'সময় (মিনিট)',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
            validator: _durationError,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _perMark,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'প্রতিটি সঠিক উত্তরের নম্বর',
              prefixIcon: Icon(Icons.star_outline),
            ),
            validator: _markError,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _negative,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ভুল উত্তরের জন্য কাটা নম্বর',
              helperText: 'নেগেটিভ মার্কিং না থাকলে ০ লিখুন।',
              prefixIcon: Icon(Icons.remove_circle_outline),
            ),
            validator: _negativeError,
          ),
          const SizedBox(height: 24),
          Text(
            'শিক্ষার্থীদের জন্য',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _shuffle,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'এলোমেলোভাবে সাজানো',
              prefixIcon: Icon(Icons.shuffle_rounded),
            ),
            items: const [
              DropdownMenuItem(
                value: 'none',
                child: Text(
                  'আগের ক্রম বজায় রাখুন',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'questions',
                child: Text(
                  'প্রশ্ন এলোমেলো করুন',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'questions_and_options',
                child: Text(
                  'প্রশ্ন ও অপশন এলোমেলো করুন',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (value) => setState(() => _shuffle = value ?? 'none'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rules,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'নির্দেশনা (ঐচ্ছিক)',
              hintText:
                  'শুরু করার আগে শিক্ষার্থীদের পড়া উচিত এমন নিয়ম লিখুন।',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    EduCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: AppTheme.accentTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'শুধু এই কোর্সে ভর্তি শিক্ষার্থীরা পরীক্ষা দেখতে ও দিতে পারবে।',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ),
  ]);

  Widget _questionsStep(BuildContext context) => _page([
    _intro(
      context,
      'প্রশ্ন তৈরি করুন',
      'একটি করে MCQ যোগ করুন। সম্পাদনা করতে যেকোনো প্রশ্নে চাপ দিন।',
    ),
    EduCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_questions.length}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _questions.length == 1
                  ? '১টি প্রশ্ন প্রস্তুত'
                  : 'প্রশ্ন প্রস্তুত',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.filledTonal(
            onPressed: _busy ? null : () => _editQuestion(),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'প্রশ্ন যোগ করুন',
          ),
        ],
      ),
    ),
    const SizedBox(height: 16),
    if (_questions.isEmpty)
      EduCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 42,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'এখনও কোনো প্রশ্ন যোগ করা হয়নি',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'একটি প্রশ্ন ও চারটি উত্তর অপশন দিয়ে শুরু করুন।',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _editQuestion(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('প্রথম প্রশ্ন যোগ করুন'),
            ),
          ],
        ),
      ),
    for (var i = 0; i < _questions.length; i++)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: EduCard(
          onTap: () => _editQuestion(i),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_questions[i]['question_text']}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'সঠিক উত্তর: ${(_questions[i]['options'] as List)[(_questions[i]['correct_option'] as num).toInt()]}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.success),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'প্রশ্নের কাজ',
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
                  PopupMenuItem(value: 'remove', child: Text('সরিয়ে ফেলুন')),
                ],
                onSelected: (action) {
                  if (action == 'edit') _editQuestion(i);
                  if (action == 'remove') {
                    setState(() => _questions.removeAt(i));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    if (_questions.isNotEmpty)
      OutlinedButton.icon(
        onPressed: _busy ? null : () => _editQuestion(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('আরও একটি প্রশ্ন যোগ করুন'),
      ),
  ]);

  Widget _reviewStep(BuildContext context) {
    final perMark = double.tryParse(_perMark.text.trim()) ?? 0;
    final total = perMark * _questions.length;
    final shuffleText = switch (_shuffle) {
      'questions' => 'প্রশ্ন',
      'questions_and_options' => 'প্রশ্ন ও অপশন',
      _ => 'বন্ধ',
    };
    return _page([
      _intro(
        context,
        'পর্যালোচনা ও প্রকাশ',
        'শিক্ষার্থীদের জন্য প্রকাশের আগে পরীক্ষাটি যাচাই করুন।',
      ),
      EduCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title.text.trim(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              widget.course.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 28),
            _summaryRow(context, 'বিষয়', _subject.text.trim()),
            _summaryRow(context, 'সময়', '${_duration.text.trim()} মিনিট'),
            _summaryRow(context, 'প্রশ্ন', '${_questions.length}টি MCQ'),
            _summaryRow(
              context,
              'মোট নম্বর',
              total.toStringAsFixed(total == total.roundToDouble() ? 0 : 2),
            ),
            _summaryRow(context, 'নেগেটিভ নম্বর', _negative.text.trim()),
            _summaryRow(context, 'সাজানোর ধরন', shuffleText),
            if (_rules.text.trim().isNotEmpty) ...[
              const Divider(height: 28),
              Text('নির্দেশনা', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(_rules.text.trim()),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('প্রশ্নের প্রিভিউ', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      for (var i = 0; i < _questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: EduCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: Text(
                'Q${i + 1}. ${_questions[i]['question_text']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              children: [
                for (var j = 0; j < 4; j++)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          j == (_questions[i]['correct_option'] as num).toInt()
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color:
                              j ==
                                  (_questions[i]['correct_option'] as num)
                                      .toInt()
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${String.fromCharCode(65 + j)}. ${(_questions[i]['options'] as List)[j]}',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 10),
      EduCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.accentTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.examId == null
                    ? 'প্রকাশ করলে ভর্তি শিক্ষার্থীরা সঙ্গে সঙ্গে এই পরীক্ষা দেখতে পারবে।'
                    : 'সংরক্ষণ করলে ভর্তি শিক্ষার্থীদের জন্য পরীক্ষাটি আপডেট হবে।',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _summaryRow(BuildContext context, String label, String value) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 126,
              child: Text(label, style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
      );

  Widget _progressHeader(BuildContext context) {
    const labels = ['তথ্য', 'প্রশ্ন', 'পর্যালোচনা'];
    const icons = [
      Icons.tune_rounded,
      Icons.assignment_outlined,
      Icons.visibility_outlined,
    ];
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: InkWell(
                        onTap: i < _step && !_busy
                            ? () => setState(() => _step = i)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i <= _step
                                    ? AppTheme.primaryColor
                                    : AppTheme.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icons[i],
                                size: 18,
                                color: i <= _step
                                    ? Colors.white
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == _step
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == _step
                                    ? AppTheme.primaryColor
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  minHeight: 4,
                  backgroundColor: AppTheme.primaryLight,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accentTeal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBar() => SafeArea(
    top: false,
    child: Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Row(
            children: [
              if (_step > 0) ...[
                OutlinedButton(
                  onPressed: _busy ? null : () => setState(() => _step--),
                  child: const Text('পেছনে'),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : (_step == 2 ? _submit : _nextStep),
                  icon: Icon(
                    _step == 2
                        ? Icons.publish_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _busy
                        ? 'সংরক্ষণ হচ্ছে...'
                        : _step == 2
                        ? (widget.examId == null
                              ? 'পরীক্ষা প্রকাশ করুন'
                              : 'পরীক্ষা সংরক্ষণ করুন')
                        : (_step == 0
                              ? 'প্রশ্নে এগিয়ে যান'
                              : 'পরীক্ষা পর্যালোচনা করুন'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.examId == null ? 'পরীক্ষা তৈরি করুন' : 'পরীক্ষা সম্পাদনা',
      ),
    ),
    body: _loading
        ? const LoadingIndicator()
        : Form(
            key: _form,
            child: Column(
              children: [
                _progressHeader(context),
                Expanded(
                  child: IndexedStack(
                    index: _step,
                    children: [
                      _detailsStep(context),
                      _questionsStep(context),
                      _reviewStep(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_loading) _actionBar(),
        const RoleBottomNavigation(
          role: AppRole.instructor,
          selectedIndex: 1,
          confirmMessage: 'সংরক্ষণ না করা পরীক্ষার পরিবর্তন হারিয়ে যাবে।',
        ),
      ],
    ),
  );
}

class _QuestionEditorScreen extends StatefulWidget {
  const _QuestionEditorScreen({required this.number, this.question});
  final int number;
  final Map<String, dynamic>? question;

  @override
  State<_QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<_QuestionEditorScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final List<TextEditingController> _options;
  late int _correct;

  @override
  void initState() {
    super.initState();
    _question = TextEditingController(
      text: '${widget.question?['question_text'] ?? ''}',
    );
    final values = widget.question?['options'] as List<dynamic>? ?? [];
    _options = List.generate(
      4,
      (i) =>
          TextEditingController(text: i < values.length ? '${values[i]}' : ''),
    );
    _correct = (widget.question?['correct_option'] as num?)?.toInt() ?? 0;
  }

  @override
  void dispose() {
    _question.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, {
      'question_text': _question.text.trim(),
      'options': _options.map((option) => option.text.trim()).toList(),
      'correct_option': _correct,
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.question == null
            ? 'প্রশ্ন ${widget.number} যোগ করুন'
            : 'প্রশ্ন ${widget.number} সম্পাদনা',
      ),
    ),
    body: Form(
      key: _form,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'MCQ প্রশ্ন লিখুন',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'চারটি অপশন লিখুন, তারপর সঠিক উত্তরের পাশের বৃত্তে চাপ দিন।',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              EduCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _question,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'প্রশ্ন',
                        hintText: 'এখানে প্রশ্ন লিখুন...',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'প্রশ্ন লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'উত্তরের অপশন',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() => _correct = i),
                              icon: Icon(
                                _correct == i
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: _correct == i
                                    ? AppTheme.success
                                    : AppTheme.textMuted,
                              ),
                              tooltip:
                                  'অপশন ${String.fromCharCode(65 + i)} সঠিক হিসেবে চিহ্নিত করুন',
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: TextFormField(
                                controller: _options[i],
                                decoration: InputDecoration(
                                  labelText:
                                      'অপশন ${String.fromCharCode(65 + i)}',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'একটি অপশন লিখুন'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      'সঠিক উত্তর: অপশন ${String.fromCharCode(65 + _correct)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          top: false,
          child: Container(
            color: AppTheme.surfaceColor,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('প্রশ্ন সংরক্ষণ করুন'),
                  ),
                ),
              ),
            ),
          ),
        ),
        const RoleBottomNavigation(
          role: AppRole.instructor,
          selectedIndex: 1,
          confirmMessage: 'এই প্রশ্নটি সংরক্ষণ করা হয়নি।',
        ),
      ],
    ),
  );
}
