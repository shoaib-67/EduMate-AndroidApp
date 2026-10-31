import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edumate/widgets/common_widgets.dart';
import 'package:edumate/models/discussion.dart';
import 'package:edumate/providers/student_provider.dart';
import 'package:edumate/screens/student/discussion_screen.dart';
import 'package:edumate/services/api_service.dart';
import 'package:edumate/services/student_service.dart';
import 'package:provider/provider.dart';

class _EmptyDiscussionProvider extends StudentProvider {
  _EmptyDiscussionProvider() : super(StudentService(ApiService()));

  @override
  Future<List<Discussion>> getCourseDiscussions(int courseId) async => [];
}

void main() {
  testWidgets('discussion empty state fits a short viewport', (tester) async {
    tester.view.physicalSize = const Size(529, 182);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.forum_rounded,
            title: 'No discussions yet',
            subtitle: 'Start the first discussion',
            actionText: 'Start discussion',
            onAction: _noop,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.text('Start discussion'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('embedded discussion fits a short course tab', (tester) async {
    tester.view.physicalSize = const Size(529, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<StudentProvider>(
        create: (_) => _EmptyDiscussionProvider(),
        child: const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 100,
                child: DiscussionScreen(courseId: 1, embedded: true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
