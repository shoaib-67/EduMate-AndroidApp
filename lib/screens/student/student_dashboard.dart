import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dashboard_widgets.dart';
import '../../widgets/my_bug_reports.dart';
import '../../widgets/profile_form.dart';
import '../../widgets/role_bottom_navigation.dart';
import '../../utils/external_links.dart';
import 'course_details_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
      context.read<StudentProvider>().loadDashboard();
      if (_currentIndex == 4) {
        context.read<StudentProvider>().loadMyBugReports();
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

  void _initializeProfileControllers(User? user) {
    _nameCtrl ??= TextEditingController(text: user?.name);
    _phoneCtrl ??= TextEditingController(text: user?.phone ?? '');
    _institutionCtrl ??= TextEditingController(text: user?.institution ?? '');
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
              : response.message ?? 'প্রোফাইল আপডেট ব্যর্থ হয়েছে',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final student = context.watch<StudentProvider>();

    return Scaffold(
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildDashboardContent(auth, student)
            : _currentIndex == 1
            ? _buildCoursesTab()
            : _currentIndex == 2
            ? _buildTestsTab()
            : _currentIndex == 3
            ? _buildProgressTab()
            : _buildEditableProfileTab(auth),
      ),
      bottomNavigationBar: RoleBottomNavigation(
        role: AppRole.student,
        selectedIndex: _currentIndex,
        onTap: (i) {
          if (i == 4) {
            context.read<StudentProvider>().loadMyBugReports();
          }
          setState(() => _currentIndex = i);
        },
      ),
    );
  }

  Widget _buildDashboardContent(AuthProvider auth, StudentProvider student) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => student.loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              name: auth.user?.name ?? 'শিক্ষার্থী',
              roleLabel: 'শিক্ষার্থী ড্যাশবোর্ড',
              icon: Icons.school_rounded,
            ),
            const SizedBox(height: 24),
            const DashboardHighlightCard(
              icon: Icons.auto_stories_rounded,
              title: 'গতি ধরে রাখুন!',
              subtitle: 'আপনার কোর্স, পরীক্ষা ও অগ্রগতি এক জায়গায় দেখুন',
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
                  icon: Icons.assignment_rounded,
                  label: 'সম্পন্ন টেস্ট',
                  value: '${student.dashboardData?['tests_completed'] ?? 0}',
                  iconColor: AppTheme.primaryColor,
                ),
                StatCard(
                  icon: Icons.bar_chart_rounded,
                  label: 'গড় স্কোর',
                  value: '${student.dashboardData?['avg_score'] ?? 0}%',
                  iconColor: AppTheme.accentTeal,
                ),
                StatCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'র‍্যাঙ্ক',
                  value: student.dashboardData?['rank'] == null
                      ? '—'
                      : '#${student.dashboardData!['rank']}',
                  iconColor: AppTheme.accentOrange,
                ),
                StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'এনরোলড কোর্স',
                  value: '${student.dashboardData?['enrolled_courses'] ?? 0}',
                  iconColor: AppTheme.accentPink,
                ),
              ],
            ),
            const SizedBox(height: 24),

            const DashboardSectionTitle('দ্রুত অ্যাকশন'),
            const SizedBox(height: 12),
            DashboardQuickAction(
              icon: Icons.assignment_rounded,
              title: 'মক টেস্ট দিন',
              subtitle: 'নতুন পরীক্ষায় অংশগ্রহণ করুন',
              color: AppTheme.primaryColor,
              onTap: () => setState(() => _currentIndex = 2),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.bar_chart_rounded,
              title: 'পারফরম্যান্স দেখুন',
              subtitle: 'আপনার অগ্রগতি বিশ্লেষণ',
              color: AppTheme.accentTeal,
              onTap: () =>
                  Navigator.of(context).pushNamed('/student/performance'),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.forum_rounded,
              title: 'আলোচনা করুন',
              subtitle: 'সহপাঠীদের সাথে প্রশ্নোত্তর',
              color: AppTheme.accentOrange,
              onTap: () =>
                  Navigator.of(context).pushNamed('/student/discussions'),
            ),
            const SizedBox(height: 10),
            DashboardQuickAction(
              icon: Icons.inventory_2_rounded,
              title: 'প্যাকেজ দেখুন',
              subtitle: 'প্রিমিয়াম ফিচার আনলক করুন',
              color: AppTheme.accentPink,
              onTap: () => Navigator.of(context).pushNamed('/student/packages'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab() {
    return _InlineCoursesView(onBack: () => _showTab(0));
  }

  Widget _buildTestsTab() {
    return _InlineTestsView(onBack: () => _showTab(1));
  }

  void _showTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildProgressTab() {
    final student = context.watch<StudentProvider>();
    final dashboard = student.dashboardData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tabHeader('অগ্রগতি', () => _showTab(2)),
          const SizedBox(height: 8),
          Text(
            'আপনার অগ্রগতি',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'নিয়মিত অনুশীলনের ফলাফল এক নজরে দেখুন',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 152,
            children: [
              StatCard(
                icon: Icons.bar_chart_rounded,
                label: 'গড় স্কোর',
                value: '${dashboard?['avg_score'] ?? 0}%',
                iconColor: AppTheme.primaryColor,
              ),
              StatCard(
                icon: Icons.assignment_rounded,
                label: 'সম্পন্ন টেস্ট',
                value: '${dashboard?['tests_completed'] ?? 0}',
                iconColor: AppTheme.accentTeal,
              ),
              StatCard(
                icon: Icons.emoji_events_rounded,
                label: 'র‍্যাঙ্ক',
                value: dashboard?['rank'] == null
                    ? '—'
                    : '#${dashboard!['rank']}',
                iconColor: AppTheme.accentOrange,
              ),
              StatCard(
                icon: Icons.menu_book_rounded,
                label: 'এনরোলড কোর্স',
                value: '${dashboard?['enrolled_courses'] ?? 0}',
                iconColor: AppTheme.accentPink,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: EduButton(
              text: 'বিস্তারিত পারফরম্যান্স দেখুন',
              icon: Icons.bar_chart_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed('/student/performance'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableProfileTab(AuthProvider auth) {
    _initializeProfileControllers(auth.user);
    final student = context.watch<StudentProvider>();
    if (!student.myBugReportsLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        student.loadMyBugReports();
      });
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _tabHeader('প্রোফাইল', () => _showTab(0), showAboutUs: true),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
            ),
            child: Text(
              (auth.user?.name ?? 'U').substring(0, 1).toUpperCase(),
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
            onTap: () => Navigator.of(context).pushNamed('/student/packages'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'প্যাকেজসমূহ',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (student.myBugReportsLoaded)
            MyBugReports(reports: student.myBugReports),
          const SizedBox(height: 16),
          EduCard(
            onTap: () => Navigator.of(context).pushNamed('/student/report-bug'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(
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

  Widget _tabHeader(
    String title,
    VoidCallback onBack, {
    bool showAboutUs = false,
  }) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          tooltip: 'হোমে ফিরুন',
        ),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        if (showAboutUs) ...[
          const Spacer(),
          TextButton(
            onPressed: () {
              openGreenEarthWebsite();
            },
            child: const Text('আমাদের সম্পর্কে'),
          ),
        ],
      ],
    );
  }
}

class _InlineCoursesView extends StatefulWidget {
  final VoidCallback onBack;

  const _InlineCoursesView({required this.onBack});

  @override
  State<_InlineCoursesView> createState() => _InlineCoursesViewState();
}

class _InlineCoursesViewState extends State<_InlineCoursesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'হোমে ফিরুন',
              ),
              Text(
                'কোর্সসমূহ',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: student.isCoursesLoading
              ? const LoadingIndicator(message: 'কোর্স লোড হচ্ছে...')
              : !student.coursesLoaded
              ? const LoadingIndicator(message: 'কোর্স লোড হচ্ছে...')
              : student.courses.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_rounded,
                  title: 'কোনো কোর্স পাওয়া যায়নি',
                  subtitle: 'অ্যাডমিন আপনাকে কোর্সে যোগ করলে এখানে দেখা যাবে',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: student.courses.length,
                  itemBuilder: (context, index) {
                    final course = student.courses[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EduCard(
                        onTap: course.id == null
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StudentCourseDetailsScreen(
                                    course: course,
                                  ),
                                ),
                              ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.play_lesson_rounded,
                                color: Colors.white,
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    course.category ?? 'সাধারণ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (course.isPremium == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'প্রিমিয়াম',
                                  style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
}

class _InlineTestsView extends StatefulWidget {
  final VoidCallback onBack;

  const _InlineTestsView({required this.onBack});

  @override
  State<_InlineTestsView> createState() => _InlineTestsViewState();
}

class _InlineTestsViewState extends State<_InlineTestsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadTests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'হোমে ফিরুন',
              ),
              Text(
                'মক টেস্ট',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: student.isTestsLoading
              ? const LoadingIndicator(message: 'টেস্ট লোড হচ্ছে...')
              : !student.testsLoaded
              ? const LoadingIndicator(message: 'টেস্ট লোড হচ্ছে...')
              : student.tests.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_rounded,
                  title: student.error == null
                      ? 'কোনো মক টেস্ট নেই'
                      : 'পরীক্ষা লোড করা যায়নি',
                  subtitle:
                      student.error ??
                      'আপনার কোর্সে নতুন পরীক্ষা প্রকাশ হলে এখানে দেখাবে',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: student.tests.length,
                  itemBuilder: (context, index) {
                    final test = student.tests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EduCard(
                        onTap: () async {
                          if ((test.attemptCount ?? 0) >= 3) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'এই পরীক্ষার ৩টি সুযোগ শেষ হয়েছে',
                                ),
                              ),
                            );
                            return;
                          }
                          final testId = test.id;
                          if (testId == null) return;
                          final studentProvider = context
                              .read<StudentProvider>();
                          final details = await studentProvider.getTestDetails(
                            testId,
                          );
                          if (!context.mounted) return;
                          if (details == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  studentProvider.error ??
                                      'পরীক্ষা খোলা যায়নি',
                                ),
                              ),
                            );
                            return;
                          }
                          final navigator = Navigator.of(context);
                          navigator.pushNamed(
                            '/student/test',
                            arguments: details,
                          );
                        },
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentTeal.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_rounded,
                                    color: AppTheme.accentTeal,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        test.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        '${test.courseTitle ?? 'কোর্স'} · ${test.subject ?? 'সাধারণ'}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (test.isCompleted == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${test.attemptCount ?? 1}/3 সুযোগ',
                                      style: const TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _testInfo(
                                  Icons.timer_outlined,
                                  '${test.duration ?? 0} মিনিট',
                                ),
                                const SizedBox(width: 16),
                                _testInfo(
                                  Icons.help_outline,
                                  '${test.totalQuestions ?? 0} প্রশ্ন',
                                ),
                                const SizedBox(width: 16),
                                _testInfo(
                                  Icons.star_outline,
                                  '${test.totalMarks ?? 0} নম্বর',
                                ),
                              ],
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

  Widget _testInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}
