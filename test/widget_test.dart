import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edumate/main.dart';
import 'package:edumate/models/course.dart';
import 'package:edumate/models/discussion.dart';
import 'package:edumate/models/mock_test.dart';
import 'package:edumate/models/package_plan.dart';
import 'package:edumate/models/instructor_student_result.dart';
import 'package:edumate/models/user.dart';
import 'package:edumate/screens/instructor/instructor_exams_screen.dart';
import 'package:edumate/screens/instructor/instructor_dashboard.dart';
import 'package:edumate/screens/admin/admin_courses_screen.dart';
import 'package:edumate/screens/admin/admin_dashboard.dart';
import 'package:edumate/screens/student/student_dashboard.dart';
import 'package:edumate/screens/student/packages_screen.dart';
import 'package:edumate/screens/student/discussion_screen.dart';
import 'package:edumate/screens/student/test_taking_screen.dart';
import 'package:edumate/providers/admin_provider.dart';
import 'package:edumate/providers/auth_provider.dart';
import 'package:edumate/providers/instructor_provider.dart';
import 'package:edumate/providers/student_provider.dart';
import 'package:edumate/services/admin_service.dart';
import 'package:edumate/services/api_service.dart';
import 'package:edumate/services/instructor_service.dart';
import 'package:edumate/services/student_service.dart';
import 'package:edumate/widgets/role_bottom_navigation.dart';
import 'package:edumate/widgets/dashboard_widgets.dart';
import 'package:edumate/widgets/profile_form.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    final apiService = ApiService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(apiService)..initialize(),
          ),
          ChangeNotifierProvider(
            create: (_) => StudentProvider(StudentService(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => InstructorProvider(InstructorService(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminProvider(AdminService(apiService)),
          ),
        ],
        child: const EduMateApp(),
      ),
    );
    await tester.pump();

    // Verify EduMate branding appears
    expect(find.text('EduMate'), findsWidgets);
  });

  testWidgets('Teacher create exam route opens course picker', (
    WidgetTester tester,
  ) async {
    final apiService = ApiService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(apiService)),
          ChangeNotifierProvider(
            create: (_) => StudentProvider(StudentService(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => InstructorProvider(InstructorService(apiService)),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminProvider(AdminService(apiService)),
          ),
        ],
        child: const EduMateApp(),
      ),
    );

    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/instructor/create-exam');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(InstructorExamCoursePickerScreen), findsOneWidget);
    expect(find.text('পরীক্ষা তৈরি করুন'), findsOneWidget);
  });

  testWidgets('Teacher can build and review an exam on a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<InstructorProvider>(
        create: (_) => _ExamTestProvider(),
        child: MaterialApp(
          home: InstructorExamsScreen(
            course: Course(id: 1, title: 'Physics'),
            openCreateOnLoad: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('পরীক্ষার তথ্য'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Weekly Quiz');
    await tester.enterText(find.byType(TextFormField).at(1), 'Physics');
    await tester.tap(find.text('প্রশ্নে এগিয়ে যান'));
    await tester.pumpAndSettle();
    expect(find.text('প্রশ্ন তৈরি করুন'), findsOneWidget);

    await tester.ensureVisible(find.text('প্রথম প্রশ্ন যোগ করুন'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('প্রথম প্রশ্ন যোগ করুন'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Two plus two?');
    for (var i = 0; i < 4; i++) {
      await tester.enterText(find.byType(TextFormField).at(i + 1), '${i + 3}');
    }
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byTooltip('অপশন B সঠিক হিসেবে চিহ্নিত করুন'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('অপশন B সঠিক হিসেবে চিহ্নিত করুন'));
    await tester.tap(find.text('প্রশ্ন সংরক্ষণ করুন'));
    await tester.pumpAndSettle();
    expect(find.text('প্রশ্ন তৈরি করুন'), findsOneWidget);

    await tester.tap(find.text('পরীক্ষা পর্যালোচনা করুন'));
    await tester.pumpAndSettle();
    expect(find.text('পর্যালোচনা ও প্রকাশ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Two plus two?'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Two plus two?'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Student can open an exam with database decimal values', (
    WidgetTester tester,
  ) async {
    final exam = MockTest.fromJson({
      'id': 5,
      'title': 'Course exam',
      'duration': 30,
      'per_mcq_mark': '1.00',
      'negative_marking': '0.25',
      'total_marks': 1,
      'questions': [
        {
          'id': 12,
          'question_text': 'Two plus two?',
          'options': ['Three', 'Four', 'Five', 'Six'],
          'option_order': [0, 1, 2, 3],
        },
      ],
    });
    expect(exam.perMcqMark, 1);
    expect(exam.negativeMarking, 0.25);

    await tester.pumpWidget(MaterialApp(home: TestTakingScreen(test: exam)));
    expect(find.text('Two plus two?'), findsOneWidget);
    expect(find.text('Four'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Exam timer resumes when submission fails', (
    WidgetTester tester,
  ) async {
    final exam = MockTest.fromJson({
      'id': 5,
      'title': 'Retry exam',
      'duration': 1,
      'questions': [
        {
          'id': 12,
          'question_text': 'Two plus two?',
          'options': ['Three', 'Four'],
          'option_order': [0, 1],
        },
      ],
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>(
        create: (_) => _FailedSubmissionProvider(),
        child: MaterialApp(home: TestTakingScreen(test: exam)),
      ),
    );
    expect(find.text('01:00'), findsOneWidget);
    await tester.tap(find.text('জমা দিন').first);
    await tester.pump();
    await tester.tap(find.text('জমা দিন').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:59'), findsOneWidget);
  });

  testWidgets('Bottom navigation opens the selected role tab', (
    WidgetTester tester,
  ) async {
    int? selectedTab;
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          bottomNavigationBar: RoleBottomNavigation(
            role: AppRole.student,
            selectedIndex: 2,
            confirmMessage: 'Unsaved answers will be lost.',
          ),
        ),
        onGenerateRoute: (settings) {
          selectedTab = settings.arguments as int?;
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Selected tab')),
          );
        },
      ),
    );

    await tester.tap(find.text('কোর্স'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved answers will be lost.'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(selectedTab, isNull);

    await tester.tap(find.text('কোর্স'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();
    expect(selectedTab, 1);
    expect(find.text('Selected tab'), findsOneWidget);
  });

  testWidgets('Admin course management is reachable from bottom navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<AdminProvider>(
            create: (_) => _AdminTestProvider(),
          ),
        ],
        child: const MaterialApp(home: AdminDashboard()),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu_book_rounded).last);
    await tester.pump();
    expect(find.byType(AdminCoursesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin can change a user role from the user menu', (
    WidgetTester tester,
  ) async {
    final admin = _AdminRoleTestProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<AdminProvider>.value(value: admin),
        ],
        child: const MaterialApp(home: AdminDashboard(initialTab: 1)),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('রোল পরিবর্তন করুন'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('শিক্ষক').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('সংরক্ষণ'));
    await tester.pumpAndSettle();
    expect(admin.selectedRole, 'instructor');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Each role dashboard uses the shared layout on a phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final dashboard in <Widget>[
      const StudentDashboard(),
      const InstructorDashboard(),
      const AdminDashboard(),
    ]) {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
            ChangeNotifierProvider<StudentProvider>(
              create: (_) => _StudentDashboardTestProvider(),
            ),
            ChangeNotifierProvider<InstructorProvider>(
              create: (_) => _InstructorDashboardTestProvider(),
            ),
            ChangeNotifierProvider<AdminProvider>(
              create: (_) => _AdminTestProvider(),
            ),
          ],
          child: MaterialApp(home: dashboard),
        ),
      );
      await tester.pump();
      expect(find.byType(DashboardHeader), findsOneWidget);
      expect(find.byType(DashboardHighlightCard), findsOneWidget);
      expect(find.byType(DashboardQuickAction), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Role quick actions cover their sections on a phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<StudentProvider>(
            create: (_) => _StudentDashboardTestProvider(),
          ),
        ],
        child: const MaterialApp(home: StudentDashboard()),
      ),
    );
    await tester.pump();
    final examAction = tester.widget<DashboardQuickAction>(
      find.ancestor(
        of: find.text('মক টেস্ট দিন'),
        matching: find.byType(DashboardQuickAction),
      ),
    );
    expect(examAction.icon, Icons.assignment_rounded);
    expect(
      tester
          .widget<DashboardQuickAction>(
            find.ancestor(
              of: find.text('প্যাকেজ দেখুন'),
              matching: find.byType(DashboardQuickAction),
            ),
          )
          .icon,
      Icons.inventory_2_rounded,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<InstructorProvider>(
            create: (_) => _InstructorDashboardTestProvider(),
          ),
        ],
        child: const MaterialApp(home: InstructorDashboard()),
      ),
    );
    await tester.pump();
    for (final title in [
      'পরীক্ষা তৈরি',
      'ফলাফল দেখুন',
      'আমার কোর্স',
      'বাগ রিপোর্ট',
      'প্রোফাইল',
    ]) {
      expect(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(DashboardQuickAction),
        ),
        findsOneWidget,
      );
    }
    expect(
      tester
          .widget<DashboardQuickAction>(
            find.ancestor(
              of: find.text('পরীক্ষা তৈরি'),
              matching: find.byType(DashboardQuickAction),
            ),
          )
          .icon,
      Icons.note_add_rounded,
    );
    final courseAction = tester.widget<DashboardQuickAction>(
      find.ancestor(
        of: find.text('আমার কোর্স'),
        matching: find.byType(DashboardQuickAction),
      ),
    );
    courseAction.onTap();
    await tester.pump();
    expect(
      tester
          .widget<RoleBottomNavigation>(find.byType(RoleBottomNavigation))
          .selectedIndex,
      1,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<AdminProvider>(
            create: (_) => _AdminTestProvider(),
          ),
        ],
        child: const MaterialApp(home: AdminDashboard()),
      ),
    );
    await tester.pump();
    for (final title in [
      'ব্যবহারকারী ম্যানেজ',
      'কোর্স ম্যানেজমেন্ট',
      'রিপোর্ট দেখুন',
      'প্যাকেজ ম্যানেজমেন্ট',
      'সেটিংস',
    ]) {
      expect(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(DashboardQuickAction),
        ),
        findsOneWidget,
      );
    }
    expect(
      tester
          .widget<DashboardQuickAction>(
            find.ancestor(
              of: find.text('রিপোর্ট দেখুন'),
              matching: find.byType(DashboardQuickAction),
            ),
          )
          .icon,
      Icons.description_rounded,
    );
    final packageAction = tester.widget<DashboardQuickAction>(
      find.ancestor(
        of: find.text('প্যাকেজ ম্যানেজমেন্ট'),
        matching: find.byType(DashboardQuickAction),
      ),
    );
    packageAction.onTap();
    await tester.pump();
    expect(
      tester
          .widget<RoleBottomNavigation>(find.byType(RoleBottomNavigation))
          .selectedIndex,
      4,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Instructor sees saved scores and each exam result', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<InstructorProvider>(
            create: (_) => _StudentResultsTestProvider(),
          ),
        ],
        child: const MaterialApp(home: InstructorDashboard(initialTab: 2)),
      ),
    );
    await tester.pump();
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('0%'), findsNothing);

    await tester.tap(find.text('Demo Student'));
    await tester.pumpAndSettle();
    expect(find.text('Class Test'), findsOneWidget);
    expect(find.text('50%'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('Instructor result models distinguish no attempts from zero score', () {
    final noAttempt = InstructorStudentResult.fromJson({
      'id': 1,
      'name': 'A',
      'email': 'a@example.com',
      'enrolled_courses': 1,
      'tests_completed': 0,
      'average_score': null,
    });
    final zeroScore = InstructorStudentResult.fromJson({
      'id': 2,
      'name': 'B',
      'email': 'b@example.com',
      'enrolled_courses': 1,
      'tests_completed': 1,
      'average_score': '0.0',
    });
    expect(noAttempt.averageScore, isNull);
    expect(zeroScore.averageScore, 0);
  });

  testWidgets('Packages show managed data and open details on a phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = _PackagesTestProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: const MaterialApp(home: PackagesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Custom Plan'), findsOneWidget);
    expect(find.text('১ মাসের প্ল্যান'), findsNothing);
    expect(provider.requests, 1);

    await tester.tap(find.text('বিস্তারিত দেখুন'));
    await tester.pumpAndSettle();
    expect(find.text('Premium lessons'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ঠিক আছে'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('প্যাকেজ রিফ্রেশ করুন'));
    await tester.pumpAndSettle();
    expect(provider.requests, 2);
  });

  testWidgets('Student profile route reuses the dashboard profile tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(ApiService())),
          ChangeNotifierProvider<StudentProvider>(
            create: (_) => _StudentDashboardTestProvider(),
          ),
        ],
        child: const EduMateApp(),
      ),
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/student/profile');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ProfileForm), findsOneWidget);
    final navigation = tester.widget<RoleBottomNavigation>(
      find.byType(RoleBottomNavigation),
    );
    expect(navigation.selectedIndex, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discussion opens replies and sends a response', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final provider = _DiscussionTestProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: const MaterialApp(home: DiscussionScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study question'));
    await tester.pumpAndSettle();
    expect(find.text('First answer'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Another answer');
    await tester.tap(find.text('উত্তর পাঠান'));
    await tester.pumpAndSettle();
    expect(provider.lastReply, 'Another answer');
    expect(find.text('Another answer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DiscussionTestProvider extends StudentProvider {
  _DiscussionTestProvider() : super(StudentService(ApiService()));

  String? lastReply;

  @override
  bool get discussionsLoaded => true;

  @override
  List<Discussion> get discussions => [
    Discussion(id: 1, title: 'Study question', content: 'How do I prepare?'),
  ];

  @override
  Future<void> loadDiscussions() async {}

  @override
  Future<Discussion?> getDiscussion(int id) async => Discussion(
    id: id,
    title: 'Study question',
    content: 'How do I prepare?',
    replies: [
      DiscussionReply(content: 'First answer', authorName: 'Tutor'),
      if (lastReply != null)
        DiscussionReply(content: lastReply!, authorName: 'Student'),
    ],
  );

  @override
  Future<bool> replyToDiscussion(int id, String content) async {
    lastReply = content;
    return true;
  }
}

class _PackagesTestProvider extends StudentProvider {
  _PackagesTestProvider() : super(StudentService(ApiService()));

  int requests = 0;

  @override
  Future<List<PackagePlan>> getPackages() async {
    requests++;
    return [
      PackagePlan(
        id: 1,
        title: 'Custom Plan',
        subtitle: 'Teacher led',
        price: '৳299',
        period: '/মাস',
        features: ['Premium lessons'],
      ),
    ];
  }
}

class _ExamTestProvider extends InstructorProvider {
  _ExamTestProvider() : super(InstructorService(ApiService()));

  @override
  Future<List<Map<String, dynamic>>> getCourseExams(int courseId) async => [];
}

class _AdminTestProvider extends AdminProvider {
  _AdminTestProvider() : super(AdminService(ApiService()));

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadCourses() async {}

  @override
  Future<void> loadPackages() async {}
}

class _AdminRoleTestProvider extends AdminProvider {
  _AdminRoleTestProvider() : super(AdminService(ApiService()));

  String? selectedRole;

  @override
  bool get usersLoaded => true;

  @override
  List<User> get users => [
    User(
      id: 7,
      name: 'Demo Student',
      email: 'student@example.com',
      role: 'student',
    ),
  ];

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<bool> updateUserRole(int id, String role) async {
    selectedRole = role;
    return true;
  }
}

class _StudentDashboardTestProvider extends StudentProvider {
  _StudentDashboardTestProvider() : super(StudentService(ApiService()));

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadMyBugReports() async {}
}

class _FailedSubmissionProvider extends StudentProvider {
  _FailedSubmissionProvider() : super(StudentService(ApiService()));

  @override
  Future<ApiResponse> submitTest(int testId, Map<int, int> answers) async {
    return ApiResponse(success: false, statusCode: 503, message: 'Try again');
  }
}

class _InstructorDashboardTestProvider extends InstructorProvider {
  _InstructorDashboardTestProvider() : super(InstructorService(ApiService()));

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<void> loadCourses() async {}
}

class _StudentResultsTestProvider extends InstructorProvider {
  _StudentResultsTestProvider() : super(InstructorService(ApiService()));

  @override
  bool get resultsLoaded => true;

  @override
  List<InstructorStudentResult> get studentResults => const [
    InstructorStudentResult(
      id: 4,
      name: 'Demo Student',
      email: 'student@example.com',
      enrolledCourses: 2,
      testsCompleted: 1,
      averageScore: 50,
    ),
  ];

  @override
  Future<void> loadDashboard() async {}

  @override
  Future<List<InstructorExamResult>> getStudentExamResults(
    int studentId,
  ) async => [
    InstructorExamResult(
      courseTitle: 'Physics',
      examTitle: 'Class Test',
      score: 50,
      correctAnswers: 1,
      totalQuestions: 2,
      completedAt: DateTime.utc(2026, 10, 11),
    ),
  ];
}
