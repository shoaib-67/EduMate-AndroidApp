import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/instructor_provider.dart';
import '../../widgets/common_widgets.dart';

class ReportBugScreen extends StatefulWidget {
  final bool isInstructor;

  const ReportBugScreen({super.key, this.isInstructor = false});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _descCtrl.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    final success = widget.isInstructor
        ? await context.read<InstructorProvider>().reportBug(
            _titleCtrl.text,
            _descCtrl.text,
          )
        : await context.read<StudentProvider>().reportBug(
            _titleCtrl.text,
            _descCtrl.text,
          );
    setState(() => _isSubmitting = false);
    if (success && mounted) {
      if (widget.isInstructor) {
        await context.read<InstructorProvider>().loadMyBugReports();
      } else {
        await context.read<StudentProvider>().loadMyBugReports();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('বাগ রিপোর্ট সফলভাবে পাঠানো হয়েছে')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('বাগ রিপোর্ট')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সমস্যা জানান',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার অভিজ্ঞতা উন্নত করতে আমাদের সাহায্য করুন',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            EduCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'সমস্যার শিরোনাম',
                      hintText: 'সংক্ষেপে সমস্যাটি লিখুন',
                      prefixIcon: Icon(Icons.bug_report_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'বিস্তারিত বিবরণ',
                      hintText: 'সমস্যাটি বিস্তারিতভাবে বর্ণনা করুন...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: EduButton(
                      text: 'রিপোর্ট পাঠান',
                      isLoading: _isSubmitting,
                      icon: Icons.send_rounded,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
