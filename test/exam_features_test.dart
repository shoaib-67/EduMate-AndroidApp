import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edumate/models/mock_test.dart';
import 'package:edumate/providers/student_provider.dart';
import 'package:edumate/screens/student/test_taking_screen.dart';
import 'package:edumate/services/api_service.dart';
import 'package:edumate/services/student_service.dart';
import 'package:edumate/services/auth_service.dart';

class RecordingStudent extends StudentProvider {
  RecordingStudent() : super(StudentService(ApiService()));
  final List<Map<String, dynamic>> submissions = [];
  bool fail = false;
  @override
  Future<ApiResponse> submitTest(
    int testId,
    Map<int, dynamic> answers, {
    String? submissionId,
    String reason = 'manual',
  }) async {
    submissions.add({
      'answers': Map.of(answers),
      'id': submissionId,
      'reason': reason,
    });
    if (fail) {
      return ApiResponse(success: false, statusCode: 0, message: 'Offline');
    }
    return ApiResponse(
      success: true,
      statusCode: 201,
      data: {
        'score': 100,
        'correct_answers': 1,
        'incorrect_answers': 0,
        'unanswered': 0,
        'earned_marks': 1,
        'total_marks': 1,
        'submission_reason': reason,
      },
    );
  }
}

class SignupApi extends ApiService {
  bool tokenSet = false;
  @override
  void setToken(String token) {
    tokenSet = true;
  }

  @override
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async => ApiResponse(
    success: true,
    statusCode: 201,
    data: {
      'token': 'test-token',
      'user': {
        'id': 1,
        'name': 'Test',
        'email': 'test@example.test',
        'role': 'student',
      },
    },
    message: 'Account created successfully',
  );
}

void main() {
  final exam = MockTest(
    id: 99,
    title: 'Mixed exam',
    duration: 5,
    questions: [
      Question(
        id: 7,
        questionText: 'Capital of Bangladesh is ___',
        options: [],
        questionType: 'fill_blank',
      ),
    ],
  );
  Future<void> mount(WidgetTester tester, RecordingStudent provider) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>.value(
        value: provider,
        child: MaterialApp(home: TestTakingScreen(test: exam)),
      ),
    );
  }

  test(
    'signup creates an authenticated session without email verification',
    () async {
      final api = SignupApi();
      final result = await AuthService(api).signup(
        name: 'Test',
        email: 'test@example.test',
        password: 'Password123',
      );
      expect(result.success, isTrue);
      expect(result.user?.email, 'test@example.test');
      expect(result.token, 'test-token');
      expect(api.tokenSet, isTrue);
    },
  );

  testWidgets(
    'typing stays active; leaving submits text once and shows result',
    (tester) async {
      final provider = RecordingStudent();
      await mount(tester, provider);
      await tester.enterText(find.byType(TextFormField), 'ঢাকা');
      expect(provider.submissions, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(provider.submissions, hasLength(1));
      expect(provider.submissions.single['answers'], {7: 'ঢাকা'});
      expect(provider.submissions.single['reason'], 'left_exam');
      expect(find.text('ফলাফল'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets(
    'failed automatic submission locks answers and retries same attempt',
    (tester) async {
      final provider = RecordingStudent()..fail = true;
      await mount(tester, provider);
      await tester.enterText(find.byType(TextFormField), 'Dhaka');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('Retry submission'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      provider.fail = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(provider.submissions, hasLength(2));
      expect(provider.submissions[0]['id'], provider.submissions[1]['id']);
      expect(
        provider.submissions[0]['answers'],
        provider.submissions[1]['answers'],
      );
      expect(find.text('ফলাফল'), findsOneWidget);
    },
  );

  testWidgets('back navigation ends exam instead of discarding answers', (
    tester,
  ) async {
    final provider = RecordingStudent();
    await mount(tester, provider);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(provider.submissions.single['reason'], 'left_exam');
    expect(find.text('ফলাফল'), findsOneWidget);
  });
}
