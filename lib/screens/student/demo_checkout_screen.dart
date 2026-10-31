import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/package_plan.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DemoCheckoutScreen extends StatefulWidget {
  const DemoCheckoutScreen({super.key, required this.plan});

  final PackagePlan plan;

  @override
  State<DemoCheckoutScreen> createState() => _DemoCheckoutScreenState();
}

class _DemoCheckoutScreenState extends State<DemoCheckoutScreen> {
  bool _submitting = false;

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final response = await context.read<StudentProvider>().demoPurchase(
      widget.plan.id,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ডেমো ক্রয় সম্পন্ন হয়েছে। কোনো টাকা নেওয়া হয়নি।'),
        ),
      );
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/student', (route) => false, arguments: 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message ?? 'ডেমো চেকআউট ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    return Scaffold(
      appBar: AppBar(title: const Text('ডেমো চেকআউট')),
      body: SafeArea(
        child: PageFrame(
          maxWidth: 520,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              EduCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('কোর্স: ${plan.courseTitle}'),
                    if (plan.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(plan.subtitle),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      '${plan.price} ${plan.period}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'এটি একটি ডেমো চেকআউট। কোনো টাকা নেওয়া হবে না। '
                'নিশ্চিত করলে কোর্সটি আপনার ড্যাশবোর্ডে যোগ হবে।',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _confirm,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ডেমো ক্রয় নিশ্চিত করুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
