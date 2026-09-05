import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

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
    const ink = Color(0xFF12253F);
    const muted = Color(0xFF607086);
    const brand = AppTheme.primaryColor;
    const brandDark = AppTheme.primaryDark;
    const line = Color(0xFFE0ECF6);

    InputDecoration inputDecoration(String label, IconData icon) =>
        InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.manrope(color: muted, fontSize: 13),
          prefixIcon: Icon(icon, size: 19, color: brandDark),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brand, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        );

    final loginCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCEBF6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16083858),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
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
                        'Login',
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
            const SizedBox(height: 13),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                  activeColor: brand,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  'লগইন অবস্থায় রাখুন',
                  style: GoogleFonts.manrope(color: muted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'পাসওয়ার্ড ভুলে গেছেন?',
                  style: GoogleFonts.manrope(color: brandDark, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    icon: auth.isLoading
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded, size: 18),
                    label: Text(
                      auth.isLoading ? 'লগইন হচ্ছে...' : 'Login',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brand,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
            const Divider(color: line, height: 18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'নতুন এখানে? ',
                    style: GoogleFonts.manrope(color: muted, fontSize: 12),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/signup'),
                    child: Text(
                      'নতুন একাউন্ট খুলুন',
                      style: GoogleFonts.manrope(
                        color: brandDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
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
