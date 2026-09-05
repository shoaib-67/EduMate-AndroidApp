import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/external_links.dart';
import 'packages_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _institutionCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name);
    _emailCtrl = TextEditingController(text: user?.email);
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _institutionCtrl = TextEditingController(text: user?.institution ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    final response = await context.read<StudentProvider>().updateProfile({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'institution': _institutionCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (response.success) {
      final auth = context.read<AuthProvider>();
      final current = auth.user;
      if (current != null) {
        await auth.updateUser(
          User(
            id: current.id,
            name: _nameCtrl.text.trim(),
            email: current.email,
            role: current.role,
            phone: _phoneCtrl.text.trim(),
            institution: _institutionCtrl.text.trim(),
            avatar: current.avatar,
            createdAt: current.createdAt,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? 'আপডেট ব্যর্থ হয়েছে')),
      );
    }
  }

  Future<void> _openAboutUs() async {
    final opened = await openGreenEarthWebsite();
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ওয়েবসাইট খোলা যাচ্ছে না')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল সম্পাদনা'),
        actions: [
          OutlinedButton.icon(
            onPressed: _openAboutUs,
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('আমাদের সম্পর্কে'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(77),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Text(
                (auth.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            EduCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'নাম',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'ইমেইল',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ফোন',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _institutionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'প্রতিষ্ঠান',
                      prefixIcon: Icon(
                        Icons.account_balance_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: EduButton(
                      text: 'আপডেট করুন',
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveProfile,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            EduCard(
              onTap: _openAboutUs,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppTheme.accentTeal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'আমাদের সম্পর্কে',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'গ্রিন আর্থ সম্পর্কে জানুন',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            EduCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PackagesScreen(),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPink.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.accentPink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'প্যাকেজসমূহ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'প্রিমিয়াম ফিচার আনলক করুন',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
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
