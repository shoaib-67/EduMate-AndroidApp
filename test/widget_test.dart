import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:edumate/main.dart';
import 'package:edumate/providers/admin_provider.dart';
import 'package:edumate/providers/auth_provider.dart';
import 'package:edumate/providers/instructor_provider.dart';
import 'package:edumate/providers/student_provider.dart';
import 'package:edumate/services/admin_service.dart';
import 'package:edumate/services/api_service.dart';
import 'package:edumate/services/instructor_service.dart';
import 'package:edumate/services/student_service.dart';

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
}
