import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common_widgets.dart';

class MyBugReports extends StatelessWidget {
  final List<dynamic> reports;

  const MyBugReports({super.key, required this.reports});

  String _statusLabel(String status) {
    switch (status) {
      case 'resolved':
        return 'Solved';
      case 'in_progress':
        return 'Working';
      default:
        return 'Unsolved';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppTheme.accentTeal;
      case 'in_progress':
        return AppTheme.accentOrange;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return EduCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, color: AppTheme.accentOrange),
              const SizedBox(width: 10),
              Text('My Bug Reports', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 14),
          if (reports.isEmpty)
            Text('You have not submitted any bug reports.', style: Theme.of(context).textTheme.bodySmall)
          else
            ...reports.map((item) {
              final report = item as Map<String, dynamic>;
              final status = report['status'] as String? ?? 'open';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report['title'] as String? ?? 'Untitled report',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(report['description'] as String? ?? ''),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
