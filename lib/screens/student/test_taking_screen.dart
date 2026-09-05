import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mock_test.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class TestTakingScreen extends StatefulWidget {
  final MockTest test;

  const TestTakingScreen({super.key, required this.test});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int _currentQuestion = 0;
  final Map<int, int> _answers = {};
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.test.duration ?? 30) * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitTest();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    final testId = widget.test.id;
    if (testId != null) {
      final submitted = await context.read<StudentProvider>().submitTest(
        testId,
        _answers,
      );
      if (!submitted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পরীক্ষা জমা দেওয়া যায়নি')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _isSubmitted = true);
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.test.questions ?? [];

    if (_isSubmitted) {
      return _buildResultView(questions);
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.test.title)),
        body: const EmptyState(
          icon: Icons.quiz_rounded,
          title: 'কোনো প্রশ্ন পাওয়া যায়নি',
        ),
      );
    }

    final question = questions[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _remainingSeconds < 300
                  ? AppTheme.error.withAlpha(25)
                  : AppTheme.accentTeal.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: _remainingSeconds < 300
                      ? AppTheme.error
                      : AppTheme.accentTeal,
                ),
                const SizedBox(width: 4),
                Text(
                  _formattedTime,
                  style: TextStyle(
                    color: _remainingSeconds < 300
                        ? AppTheme.error
                        : AppTheme.accentTeal,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentQuestion + 1) / questions.length,
            backgroundColor: AppTheme.cardColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
            minHeight: 3,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number
                  Text(
                    'প্রশ্ন ${_currentQuestion + 1}/${questions.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),

                  // Question text
                  EduCard(
                    hasGradientBorder: true,
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      question.questionText,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...List.generate(question.options.length, (i) {
                    final isSelected = _answers[_currentQuestion] == i;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () {
                          setState(() => _answers[_currentQuestion] = i);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withAlpha(25)
                                : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFFDCE5EF),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.cardColorLight,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  question.options[i],
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: const Color(0xFFDCE5EF))),
            ),
            child: Row(
              children: [
                if (_currentQuestion > 0)
                  Expanded(
                    child: EduButton(
                      text: 'আগের প্রশ্ন',
                      isOutlined: true,
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => setState(() => _currentQuestion--),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 12),
                Expanded(
                  child: _currentQuestion < questions.length - 1
                      ? EduButton(
                          text: 'পরের প্রশ্ন',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () => setState(() => _currentQuestion++),
                        )
                      : EduButton(
                          text: 'জমা দিন',
                          icon: Icons.check_circle_rounded,
                          onPressed: () => _showSubmitDialog(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('পরীক্ষা জমা দিন?'),
        content: Text(
          'উত্তর দেওয়া হয়েছে: ${_answers.length}/${widget.test.questions?.length ?? 0}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ফিরে যান'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            child: const Text('জমা দিন'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(List<Question> questions) {
    int correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].correctOption) correct++;
    }
    final percentage = questions.isNotEmpty
        ? (correct / questions.length * 100)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('ফলাফল')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: percentage >= 60
                    ? AppTheme.successGradient
                    : const LinearGradient(
                        colors: [AppTheme.error, Color(0xFFFF4040)],
                      ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (percentage >= 60 ? AppTheme.success : AppTheme.error)
                            .withAlpha(77),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              percentage >= 60 ? 'অভিনন্দন! 🎉' : 'আরও চেষ্টা করুন!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'সঠিক',
                    value: '$correct',
                    iconColor: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.cancel_outlined,
                    label: 'ভুল',
                    value: '${questions.length - correct}',
                    iconColor: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: EduButton(
                text: 'ড্যাশবোর্ডে ফিরে যান',
                icon: Icons.home_rounded,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
