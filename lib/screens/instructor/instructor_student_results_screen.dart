import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/instructor_student_result.dart';
import '../../providers/instructor_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class InstructorStudentResultsScreen extends StatefulWidget {
  const InstructorStudentResultsScreen({super.key, required this.student});

  final InstructorStudentResult student;

  @override
  State<InstructorStudentResultsScreen> createState() =>
      _InstructorStudentResultsScreenState();
}

class _InstructorStudentResultsScreenState
    extends State<InstructorStudentResultsScreen> {
  late Future<List<InstructorExamResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = context.read<InstructorProvider>().getStudentExamResults(
      widget.student.id,
    );
  }

  Future<void> _refresh() async {
    final next = context.read<InstructorProvider>().getStudentExamResults(
      widget.student.id,
    );
    setState(() => _results = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder shows the error and provides a retry action.
    }
  }

  String _score(double score) =>
      '${score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1)}%';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.student.name)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.instructor,
        selectedIndex: 2,
      ),
      body: FutureBuilder<List<InstructorExamResult>>(
        future: _results,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ফলাফল লোড করা যায়নি'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('আবার চেষ্টা করুন'),
                  ),
                ],
              ),
            );
          }
          final results = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                EduCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.student.email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.student.enrolledCourses}টি কোর্স • ${results.length}টি পরীক্ষা দেওয়া হয়েছে',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        results.isEmpty
                            ? 'গড় স্কোর: এখনও ফলাফল নেই'
                            : 'গড় স্কোর: ${_score(results.map((item) => item.score).reduce((a, b) => a + b) / results.length)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'পরীক্ষার ফলাফল',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'এখনও কোনো পরীক্ষা দেওয়া হয়নি',
                    subtitle:
                        'শিক্ষার্থী পরীক্ষা জমা দিলে ফলাফল এখানে দেখা যাবে',
                  )
                else
                  for (final result in results) ...[
                    EduCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  result.examTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  result.courseTitle,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  '${result.correctAnswers}/${result.totalQuestions}টি সঠিক • ${result.completedAt == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(result.completedAt!.toLocal())}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _score(result.score),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}
