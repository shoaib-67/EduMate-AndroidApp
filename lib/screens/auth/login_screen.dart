import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (!success || !mounted) return;

    final destination = switch (authProvider.userRole.toLowerCase()) {
      'admin' => '/admin',
      'teacher' || 'instructor' => '/instructor',
      _ => '/student',
    };
    Navigator.of(context)
        .pushNamedAndRemoveUntil(destination, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    const ink = AppTheme.textPrimary;
    const muted = AppTheme.textSecondary;
    const brand = AppTheme.primaryColor;
    const brandDark = AppTheme.primaryDark;

    InputDecoration inputDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 19, color: brandDark),
        );

    final loginCard = EduCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পরের সেশনের জন্য প্রস্তুত?',
                        style: GoogleFonts.manrope(
                          color: brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'লগইন',
                        style: GoogleFonts.inter(
                          color: ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার একাউন্টে লগইন করে প্রস্তুতিকে এগিয়ে নিন।',
              style: GoogleFonts.manrope(color: muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              style: GoogleFonts.manrope(color: ink, fontSize: 14),
              decoration: inputDecoration('ইমেইল', Icons.email_outlined),
              validator: (value) {
                if (value == null || value.isEmpty) return 'ইমেইল দিন';
                if (!value.contains('@')) return 'সঠিক ইমেইল দিন';
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _handleLogin(),
              style: GoogleFonts.manrope(color: ink, fontSize: 14),
              decoration: inputDecoration('পাসওয়ার্ড', Icons.lock_outline)
                  .copyWith(
                    suffixIcon: TextButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      child: Text(
                        _obscurePassword ? 'দেখুন' : 'লুকান',
                        style: GoogleFonts.manrope(
                          color: brandDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'পাসওয়ার্ড দিন';
                if (value.length < 6) {
                  return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: EduButton(
                    text: auth.isLoading ? 'লগইন হচ্ছে...' : 'লগইন',
                    isLoading: auth.isLoading,
                    icon: Icons.login_rounded,
                    onPressed: _handleLogin,
                  ),
                );
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    auth.error!,
                    style: GoogleFonts.manrope(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 24),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'নতুন এখানে? ',
                      style: GoogleFonts.manrope(color: muted, fontSize: 12),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/signup'),
                      child: const Text('নতুন একাউন্ট খুলুন'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x38075D88),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'EduMate',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0E3F68),
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'শিক্ষার্থীদের প্রস্তুতির সহজ সঙ্গী',
                    style: GoogleFonts.manrope(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 26),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: loginCard,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
