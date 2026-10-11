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
import '../../utils/external_links.dart';
import 'course_content_screen.dart';
import 'instructor_exams_screen.dart';
import 'instructor_student_results_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
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
    _currentIndex = widget.initialTab;
    _initializeProfileControllers(context.read<AuthProvider>().user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadDashboard();
      if (_currentIndex == 3) {
        context.read<InstructorProvider>().loadMyBugReports();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _phoneCtrl?.dispose();
    _institutionCtrl?.dispose();
    super.dispose();
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
            ? _buildDashboard(auth, instructor)
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
      onRefresh: () => instructor.loadDashboard(),
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
              mainAxisExtent: 152,
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
              onTap: () => setState(() => _currentIndex = 1),
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
        instructor.loadCourses();
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Expanded(
                child: Text(
                  'আমার কোর্সসমূহ',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: instructor.isCoursesLoading || !instructor.coursesLoaded
              ? const LoadingIndicator()
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
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Expanded(
                child: Text(
                  'শিক্ষার্থীদের ফলাফল',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              IconButton(
                onPressed: instructor.isResultsLoading
                    ? null
                    : instructor.loadStudentResults,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'ফলাফল রিফ্রেশ করুন',
              ),
            ],
          ),
        ),
        Expanded(
          child: instructor.isResultsLoading || !instructor.resultsLoaded
              ? const LoadingIndicator()
              : instructor.resultsError != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        instructor.resultsError!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: instructor.loadStudentResults,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('আবার চেষ্টা করুন'),
                      ),
                    ],
                  ),
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
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Text(
                'প্রোফাইল',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  openGreenEarthWebsite();
                },
                child: const Text('আমাদের সম্পর্কে'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Text(
              (auth.user?.name ?? 'I').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auth.user?.name ?? '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            auth.user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ইন্সট্রাক্টর',
              style: TextStyle(
                color: AppTheme.accentTeal,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
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
