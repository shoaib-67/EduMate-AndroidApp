import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/instructor_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/my_bug_reports.dart';
import '../../utils/external_links.dart';
import 'course_content_screen.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _currentIndex = 0;
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
    _initializeProfileControllers(context.read<AuthProvider>().user);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InstructorProvider>().loadDashboard();
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: const Color(0xFFDCE5EF))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 3) {
              context.read<InstructorProvider>().loadMyBugReports();
            }
            setState(() => _currentIndex = i);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'ড্যাশবোর্ড',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'কোর্স',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'শিক্ষার্থী',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'প্রোফাইল',
            ),
          ],
        ),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ইন্সট্রাক্টর প্যানেল',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.user?.name ?? 'ইন্সট্রাক্টর',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
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
                  icon: Icons.quiz_rounded,
                  label: 'তৈরি পরীক্ষা',
                  value: '${instructor.dashboardData?['total_exams'] ?? 0}',
                  iconColor: AppTheme.accentOrange,
                ),
                StatCard(
                  icon: Icons.star_rounded,
                  label: 'গড় রেটিং',
                  value: '${instructor.dashboardData?['avg_rating'] ?? '0.0'}',
                  iconColor: AppTheme.accentPink,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'দ্রুত অ্যাকশন',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _quickAction(
              Icons.add_circle_rounded,
              'নতুন কোর্স তৈরি',
              'কোর্স কনটেন্ট যোগ করুন',
              AppTheme.primaryColor,
              () {
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 10),
            _quickAction(
              Icons.assignment_add,
              'পরীক্ষা তৈরি',
              'নতুন মক টেস্ট সেট করুন',
              AppTheme.accentTeal,
              () {
                Navigator.of(context).pushNamed('/instructor/create-exam');
              },
            ),
            const SizedBox(height: 10),
            _quickAction(
              Icons.analytics_rounded,
              'ফলাফল দেখুন',
              'শিক্ষার্থীদের পারফরম্যান্স',
              AppTheme.accentOrange,
              () {
                setState(() => _currentIndex = 2);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return EduCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(sub, style: Theme.of(context).textTheme.bodySmall),
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
              IconButton(
                onPressed: () => _showCreateCourseDialog(),
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
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
                  subtitle: 'নতুন কোর্স তৈরি করুন',
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
                                    builder: (_) =>
                                        InstructorCourseContentScreen(course: course),
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
                            PopupMenuButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textMuted,
                              ),
                              color: AppTheme.cardColor,
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('সম্পাদনা'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('মুছুন'),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'delete' && course.id != null) {
                                  instructor.deleteCourse(course.id!);
                                }
                              },
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

  void _showCreateCourseDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('নতুন কোর্স', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'কোর্সের নাম',
                hintText: 'কোর্সের শিরোনাম',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'বিবরণ',
                hintText: 'কোর্সের বিবরণ',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: EduButton(
                text: 'তৈরি করুন',
                icon: Icons.add_rounded,
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty) {
                    final instructor = context.read<InstructorProvider>();
                    final success = await instructor.createCourse({
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                    });
                    if (!ctx.mounted) return;
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            instructor.error ?? 'কোর্স তৈরি করা যায়নি',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        ),
      ),
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
              Text(
                'শিক্ষার্থীদের ফলাফল',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
        ),
        Expanded(
          child: instructor.isResultsLoading || !instructor.resultsLoaded
              ? const LoadingIndicator()
              : instructor.studentResults.isEmpty
              ? const EmptyState(
                  icon: Icons.people_rounded,
                  title: 'কোনো ফলাফল নেই',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: instructor.studentResults.length,
                  itemBuilder: (context, index) {
                    final student =
                        instructor.studentResults[index]
                            as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EduCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (student['name'] as String? ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student['name'] as String? ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    student['email'] as String? ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${student['score'] ?? 0}%',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
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
          EduCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl!,
                  decoration: const InputDecoration(
                    labelText: 'নাম',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: auth.user?.email,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl!,
                  decoration: const InputDecoration(
                    labelText: 'ফোন',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _institutionCtrl!,
                  decoration: const InputDecoration(
                    labelText: 'প্রতিষ্ঠান',
                    prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: EduButton(
                    text: 'আপডেট করুন',
                    icon: Icons.save_rounded,
                    isLoading: _isSavingProfile,
                    onPressed: _isSavingProfile
                        ? null
                        : () => _saveProfile(auth),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          EduCard(
            onTap: () => Navigator.of(context).pushNamed(
              '/instructor/report-bug',
            ),
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
