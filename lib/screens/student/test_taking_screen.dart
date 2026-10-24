import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/mock_test.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class TestTakingScreen extends StatefulWidget {
  final MockTest test;

  const TestTakingScreen({super.key, required this.test});

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen>
    with WidgetsBindingObserver {
  int _currentQuestion = 0;
  final Map<int, dynamic> _answers = {};
  final String _submissionId = List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  String? _submissionReason;
  String? _submissionError;
  late DateTime _deadline;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitted = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = (widget.test.duration ?? 30) * 60;
    _deadline = DateTime.now().add(Duration(seconds: _remainingSeconds));
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds = max(
        0,
        _deadline.difference(DateTime.now()).inSeconds,
      );
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitTest(reason: 'time_expired');
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isSubmitted) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _submitTest(reason: 'left_exam');
    } else if (state == AppLifecycleState.resumed &&
        _submissionReason != null) {
      _submitTest(reason: _submissionReason!);
    }
  }

  Future<void> _submitTest({String reason = 'manual'}) async {
    if (_isSubmitting || _isSubmitted) return;
    setState(() {
      _isSubmitting = true;
      _submissionReason ??= reason;
      _submissionError = null;
    });
    _timer?.cancel();
    try {
      final testId = widget.test.id;
      if (testId != null) {
        final questions = widget.test.questions ?? [];
        final answersById = <int, dynamic>{};
        for (var i = 0; i < questions.length; i++) {
          final id = questions[i].id;
          if (id != null && _answers.containsKey(i)) {
            final chosen = _answers[i]!;
            answersById[id] = questions[i].isFillBlank
                ? chosen
                : questions[i].optionOrder?[chosen as int] ?? chosen;
          }
        }
        final response = await context.read<StudentProvider>().submitTest(
          testId,
          answersById,
          submissionId: _submissionId,
          reason: _submissionReason!,
        );
        if (!mounted) return;
        if (!response.success) {
          setState(() {
            _isSubmitting = false;
            _submissionError =
                response.message ?? 'Could not submit. Reconnect and retry.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'পরীক্ষা জমা দেওয়া যায়নি'),
            ),
          );
          return;
        }
        _result = Map<String, dynamic>.from(response.data as Map);
      }
      if (!mounted) return;
      setState(() {
        _isSubmitted = true;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionError =
            'Connection failed. Your answers are locked. Reconnect and retry.';
      });
    }
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

    if (_submissionReason != null) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Exam ended'),
            automaticallyImplyLeading: false,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _submissionReason == 'left_exam'
                        ? 'You left the exam screen. Your answers are locked and are being submitted.'
                        : 'Your answers are locked while the result is saved.',
                  ),
                  const SizedBox(height: 20),
                  if (_isSubmitting) const CircularProgressIndicator(),
                  if (_submissionError != null) ...[
                    Text(_submissionError!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _submitTest(reason: _submissionReason!),
                      child: const Text('Retry submission'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        bottomNavigationBar: const RoleBottomNavigation(
          role: AppRole.student,
          selectedIndex: 2,
        ),
        appBar: AppBar(title: Text(widget.test.title)),
        body: const EmptyState(
          icon: Icons.assignment_rounded,
          title: 'কোনো প্রশ্ন পাওয়া যায়নি',
        ),
      );
    }

    final question = questions[_currentQuestion];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _submitTest(reason: 'left_exam');
      },
      child: Scaffold(
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
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: const Border(top: BorderSide(color: Color(0xFFDCE5EF))),
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
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Leaving this screen, switching tabs/apps, or pressing Home ends and submits your exam automatically.',
              ),
            ),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (question.isFillBlank)
                      TextFormField(
                        key: ValueKey(question.id ?? _currentQuestion),
                        initialValue:
                            _answers[_currentQuestion] as String? ?? '',
                        maxLength: 500,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Your answer',
                          hintText: 'Fill in the blank',
                        ),
                        onChanged: (value) {
                          if (_submissionReason != null) return;
                          if (value.trim().isEmpty) {
                            _answers.remove(_currentQuestion);
                          } else {
                            _answers[_currentQuestion] = value;
                          }
                        },
                      )
                    else
                      ...List.generate(question.options.length, (i) {
                        final isSelected = _answers[_currentQuestion] == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              if (_submissionReason != null) return;
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
          ],
        ),
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
    final correct = (_result?['correct_answers'] as num?)?.toInt() ?? 0;
    final percentage = (_result?['score'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.student,
        selectedIndex: 2,
      ),
      appBar: AppBar(title: const Text('ফলাফল')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (_result?['submission_reason'] == 'left_exam')
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Exam automatically submitted because you left the exam screen.',
                ),
              ),
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
              'Marks: ${_result?['earned_marks'] ?? 0} / ${_result?['total_marks'] ?? 0}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
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
                    value:
                        '${_result?['incorrect_answers'] ?? questions.length - correct}',
                    iconColor: AppTheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Unanswered: ${_result?['unanswered'] ?? 0}'),
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
