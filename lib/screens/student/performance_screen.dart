import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadPerformance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('পারফরম্যান্স')),
      body: student.isPerformanceLoading || !student.performanceLoaded
          ? const LoadingIndicator(message: 'ডাটা লোড হচ্ছে...')
          : student.performance == null
          ? const EmptyState(
              icon: Icons.analytics_rounded,
              title: 'কোনো পারফরম্যান্স ডাটা নেই',
              subtitle: 'মক টেস্ট দিলে এখানে আপনার অগ্রগতি দেখবেন',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'গড় স্কোর',
                        value:
                            '${student.performance!.averageScore?.toStringAsFixed(1) ?? 0}%',
                        iconColor: AppTheme.primaryColor,
                      ),
                      StatCard(
                        icon: Icons.quiz_rounded,
                        label: 'মোট টেস্ট',
                        value: '${student.performance!.totalTestsTaken ?? 0}',
                        iconColor: AppTheme.accentTeal,
                      ),
                      StatCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'র‍্যাঙ্ক',
                        value: '#${student.performance!.rank ?? '-'}',
                        iconColor: AppTheme.accentOrange,
                      ),
                      StatCard(
                        icon: Icons.check_circle_outline,
                        label: 'সঠিক উত্তর',
                        value: '${student.performance!.totalCorrect ?? 0}',
                        iconColor: AppTheme.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subject-wise chart
                  if (student.performance!.subjectWise != null &&
                      student.performance!.subjectWise!.isNotEmpty) ...[
                    Text(
                      'বিষয়ভিত্তিক পারফরম্যান্স',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    EduCard(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 100,
                            barGroups: student.performance!.subjectWise!
                                .asMap()
                                .entries
                                .map((entry) {
                                  return BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.score,
                                        gradient: AppTheme.primaryGradient,
                                        width: 20,
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 &&
                                        idx <
                                            student
                                                .performance!
                                                .subjectWise!
                                                .length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          student
                                              .performance!
                                              .subjectWise![idx]
                                              .subject,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Recent results
                  if (student.performance!.recentResults != null &&
                      student.performance!.recentResults!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'সাম্প্রতিক ফলাফল',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...student.performance!.recentResults!.map(
                      (result) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: EduCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (result.score ?? 0) >= 60
                                      ? AppTheme.success.withAlpha(25)
                                      : AppTheme.error.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${result.score?.toStringAsFixed(0) ?? 0}%',
                                    style: TextStyle(
                                      color: (result.score ?? 0) >= 60
                                          ? AppTheme.success
                                          : AppTheme.error,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.testTitle ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    Text(
                                      '${result.correctAnswers ?? 0}/${result.totalQuestions ?? 0} সঠিক',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
