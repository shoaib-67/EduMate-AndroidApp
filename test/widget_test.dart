import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edumate/main.dart';
import 'package:edumate/models/course.dart';
import 'package:edumate/models/mock_test.dart';
import 'package:edumate/screens/instructor/instructor_exams_screen.dart';
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
}

class _ExamTestProvider extends InstructorProvider {
  _ExamTestProvider() : super(InstructorService(ApiService()));

  @override
  Future<List<Map<String, dynamic>>> getCourseExams(int courseId) async => [];
}
