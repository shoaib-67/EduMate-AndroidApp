import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/instructor_provider.dart';
import '../../models/user.dart';
import '../../models/instructor_student_result.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dashboard_widgets.dart';
import '../../widgets/my_bug_reports.dart';
import '../../widgets/profile_form.dart';
import '../../widgets/role_bottom_navigation.dart';
import 'course_content_screen.dart';
import 'instructor_exams_screen.dart';
import 'instructor_student_results_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard>
    with WidgetsBindingObserver {
  late int _currentIndex;
  TextEditingController? _nameCtrl;
  TextEditingController? _phoneCtrl;
  TextEditingController? _institutionCtrl;
  bool _isSavingProfile = false;

  Future<void> _handleLogout(AuthProvider auth) async {
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialTab;
    _initializeProfileControllers(context.read<AuthProvider>().user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final instructor = context.read<InstructorProvider>();
      instructor.loadDashboard();
      instructor.loadCourses();
      if (_currentIndex == 3) {
        context.read<InstructorProvider>().loadMyBugReports();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl?.dispose();
    _phoneCtrl?.dispose();
    _institutionCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final instructor = context.read<InstructorProvider>();
      instructor.loadDashboard();
      instructor.loadCourses();
    }
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    final name = _nameCtrl?.text.trim() ?? '';
    if (name.isEmpty) return;
    setState(() => _isSavingProfile = true);
    final response = await auth.updateProfile(
      name: name,
      phone: _phoneCtrl?.text.trim(),
      institution: _institutionCtrl?.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSavingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'প্রোফাইল আপডেট হয়েছে'
              : response.message ?? 'আপডেট ব্যর্থ হয়েছে',
        ),
      ),
    );
  }

  void _initializeProfileControllers(User? user) {
    _nameCtrl ??= TextEditingController(text: user?.name);
    _phoneCtrl ??= TextEditingController(text: user?.phone ?? '');
    _institutionCtrl ??= TextEditingController(text: user?.institution ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final instructor = context.watch<InstructorProvider>();

    return Scaffold(
      body: SafeArea(
        child: _currentIndex == 0
            ? instructor.dashboardError != null
                  ? EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'ড্যাশবোর্ড লোড করা যায়নি',
                      subtitle: instructor.dashboardError!,
                      actionText: 'আবার চেষ্টা করুন',
                      onAction: instructor.loadDashboard,
                    )
                  : _buildDashboard(auth, instructor)
            : _currentIndex == 1
            ? _buildCoursesTab(instructor)
            : _currentIndex == 2
            ? _buildStudentsTab(instructor)
            : _buildProfileTab(auth),
      ),
      bottomNavigationBar: RoleBottomNavigation(
        role: AppRole.instructor,
        selectedIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) {
            instructor.loadDashboard();
          }
          if (i == 1) {
            instructor.loadCourses();
          }
          if (i == 2) {
            instructor.loadStudentResults();
          }
          if (i == 3) {
            context.read<InstructorProvider>().loadMyBugReports();
          }
          setState(() => _currentIndex = i);
        },
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth, InstructorProvider instructor) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async {
        await Future.wait([
          instructor.loadDashboard(),
          instructor.loadCourses(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              name: auth.user?.name ?? 'ইন্সট্রাক্টর',
              roleLabel: 'ইন্সট্রাক্টর ড্যাশবোর্ড',
              icon: Icons.co_present_rounded,
            ),
            const SizedBox(height: 24),
            const DashboardHighlightCard(
              icon: Icons.cast_for_education_rounded,
              title: 'আপনার ক্লাস প্রস্তুত করুন',
              subtitle:
                  'কোর্সের কনটেন্ট, পরীক্ষা ও শিক্ষার্থীদের অগ্রগতি দেখুন',
            ),
            const SizedBox(height: 24),
            const DashboardSectionTitle('আপনার পরিসংখ্যান'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: StatCard.gridExtent(context),
              children: [
                StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'মোট কোর্স',
                  value: '${instructor.dashboardData?['total_courses'] ?? 0}',
                  iconColor: AppTheme.primaryColor,
                ),
                StatCard(
                  icon: Icons.people_rounded,
                  label: 'মোট শিক্ষার্থী',
                  value: '${instructor.dashboardData?['total_students'] ?? 0}',
                  iconColor: AppTheme.accentTeal,
                ),
                StatCard(
                  icon: Icons.assignment_rounded,
                  label: 'তৈরি পরীক্ষা',
                  value: '${instructor.dashboardData?['total_exams'] ?? 0}',
                  iconColor: AppTheme.accentOrange,
                ),
                StatCard(
                  icon: Icons.star_rounded,
                  label: 'গড় রেটিং',
                  value: instructor.dashboardData?['avg_rating'] == null
                      ? '—'
                      : '${instructor.dashboardData!['avg_rating']}/5',
                  iconColor: AppTheme.accentPink,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const DashboardSectionTitle('Assigned courses'),
            const SizedBox(height: 12),
            if (instructor.isCoursesLoading && !instructor.coursesLoaded)
              const LoadingIndicator()
            else if (instructor.coursesError != null)
              EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load assigned courses',
                subtitle: instructor.coursesError!,
                actionText: 'Retry',
                onAction: instructor.loadCourses,
              )
            else if (instructor.courses.isEmpty)
              const Text('No courses are assigned to you yet.')
            else
              for (final course in instructor.courses.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: EduCard(
                    onTap: course.id == null
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  InstructorCourseContentScreen(course: course),
                            ),
                          ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(course.title)),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            const DashboardSectionTitle('দ্রুত অ্যাকশন'),
            const SizedBox(height: 12),
            DashboardQuickAction(
              icon: Icons.note_add_rounded,
              title: 'পরীক্ষা তৈরি',
              subtitle: 'কোর্স নির্বাচন করে MCQ পরীক্ষা প্রকাশ করুন',
              color: AppTheme.accentTeal,
              onTap: () =>
                  Navigator.of(context).pushNamed('/instructor/create-exam'),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.fact_check_rounded,
              title: 'ফলাফল দেখুন',
              subtitle: 'শিক্ষার্থীদের পারফরম্যান্স',
              color: AppTheme.accentOrange,
              onTap: () {
                instructor.loadStudentResults();
                setState(() => _currentIndex = 2);
              },
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.menu_book_rounded,
              title: 'আমার কোর্স',
              subtitle: 'কোর্সের কনটেন্ট ও পরীক্ষা পরিচালনা করুন',
              color: AppTheme.primaryColor,
              onTap: () {
                instructor.loadCourses();
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.forum_rounded,
              title: 'শিক্ষার্থীদের আলোচনা',
              subtitle: 'প্রশ্ন পড়ুন ও উত্তর দিন',
              color: AppTheme.accentTeal,
              onTap: () =>
                  Navigator.of(context).pushNamed('/instructor/discussions'),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.bug_report_outlined,
              title: 'বাগ রিপোর্ট',
              subtitle: 'অ্যাপের কোনো সমস্যা জানিয়ে দিন',
              color: AppTheme.accentPink,
              onTap: () =>
                  Navigator.of(context).pushNamed('/instructor/report-bug'),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.person_rounded,
              title: 'প্রোফাইল',
              subtitle: 'তথ্য সম্পাদনা ও রিপোর্ট দেখুন',
              color: AppTheme.primaryColor,
              onTap: () {
                instructor.loadMyBugReports();
                setState(() => _currentIndex = 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab(InstructorProvider instructor) {
    if (!instructor.coursesLoaded && !instructor.isCoursesLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !instructor.isCoursesLoading) instructor.loadCourses();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RolePageHeader(
          title: 'আমার কোর্সসমূহ',
          onBack: () => setState(() => _currentIndex = 0),
          action: IconButton(
            onPressed: instructor.isCoursesLoading
                ? null
                : instructor.loadCourses,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh assigned courses',
          ),
        ),
        Expanded(
          child: instructor.isCoursesLoading || !instructor.coursesLoaded
              ? const LoadingIndicator()
              : instructor.coursesError != null
              ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load assigned courses',
                  subtitle: instructor.coursesError!,
                  actionText: 'Retry',
                  onAction: instructor.loadCourses,
                )
              : instructor.courses.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'কোনো কোর্স নেই',
                  subtitle: 'অ্যাডমিন কোর্স অ্যাসাইন করলে এখানে দেখা যাবে',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: instructor.courses.length,
                  itemBuilder: (context, index) {
                    final course = instructor.courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EduCard(
                        onTap: course.id == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => InstructorCourseContentScreen(
                                    course: course,
                                  ),
                                ),
                              ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_lesson_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    '${course.enrolledCount ?? 0} শিক্ষার্থী',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (course.id != null)
                              IconButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InstructorExamsScreen(course: course),
                                  ),
                                ),
                                icon: const Icon(Icons.assignment_outlined),
                                tooltip: 'কোর্সের পরীক্ষা তৈরি ও পরিচালনা',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentsTab(InstructorProvider instructor) {
    if (!instructor.resultsLoaded && !instructor.isResultsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        instructor.loadStudentResults();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RolePageHeader(
          title: 'শিক্ষার্থীদের ফলাফল',
          onBack: () => setState(() => _currentIndex = 1),
          action: IconButton(
            onPressed: instructor.isResultsLoading
                ? null
                : instructor.loadStudentResults,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'ফলাফল রিফ্রেশ করুন',
          ),
        ),
        Expanded(
          child: instructor.isResultsLoading || !instructor.resultsLoaded
              ? const LoadingIndicator()
              : instructor.resultsError != null
              ? EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'শিক্ষার্থীদের ফলাফল লোড করা যায়নি',
                  subtitle: instructor.resultsError!,
                  actionText: 'আবার চেষ্টা করুন',
                  onAction: instructor.loadStudentResults,
                )
              : RefreshIndicator(
                  onRefresh: instructor.loadStudentResults,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Text(
                        'আপনার কোর্সে ${instructor.studentResults.length} জন শিক্ষার্থী',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      if (instructor.studentResults.isEmpty)
                        const EmptyState(
                          icon: Icons.people_rounded,
                          title: 'এখনও কোনো শিক্ষার্থী নেই',
                          subtitle:
                              'অ্যাডমিন শিক্ষার্থী যোগ করলে এখানে দেখা যাবে',
                        )
                      else
                        for (final student in instructor.studentResults) ...[
                          _studentResultCard(instructor, student),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _studentResultCard(
    InstructorProvider instructor,
    InstructorStudentResult student,
  ) {
    final score = student.averageScore;
    return EduCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InstructorStudentResultsScreen(student: student),
          ),
        );
        if (mounted) instructor.loadStudentResults();
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withAlpha(25),
            child: Text(
              student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
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
                  student.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  student.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${student.enrolledCourses}টি কোর্স • ${student.testsCompleted}টি পরীক্ষা',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score == null
                    ? '—'
                    : '${score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1)}%',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppTheme.primaryColor),
              ),
              Text('গড় স্কোর', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(AuthProvider auth) {
    _initializeProfileControllers(auth.user);
    final instructor = context.watch<InstructorProvider>();
    if (!instructor.myBugReportsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        instructor.loadMyBugReports();
      });
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          RolePageHeader(
            title: 'প্রোফাইল',
            onBack: () => setState(() => _currentIndex = 2),
            showAboutUs: true,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 20),
          ProfileIdentity(
            name: auth.user?.name ?? '',
            email: auth.user?.email ?? '',
            roleLabel: 'ইন্সট্রাক্টর',
            roleColor: AppTheme.accentTeal,
          ),
          const SizedBox(height: 32),
          ProfileForm(
            nameController: _nameCtrl!,
            phoneController: _phoneCtrl!,
            institutionController: _institutionCtrl!,
            email: auth.user?.email,
            isSaving: _isSavingProfile,
            onSave: () => _saveProfile(auth),
          ),
          const SizedBox(height: 16),
          EduCard(
            onTap: () =>
                Navigator.of(context).pushNamed('/instructor/report-bug'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.bug_report_outlined,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'বাগ রিপোর্ট',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (instructor.myBugReportsLoaded)
            MyBugReports(reports: instructor.myBugReports),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: EduButton(
              text: 'লগআউট',
              isOutlined: true,
              icon: Icons.logout_rounded,
              onPressed: () => _handleLogout(auth),
            ),
          ),
        ],
      ),
    );
  }
}
