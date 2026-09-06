import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../utils/external_links.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _institutionCtrl;
  User? _profileUser;
  bool _isSavingProfile = false;

  Future<void> _handleLogout(AuthProvider auth) async {
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name);
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _institutionCtrl = TextEditingController(text: user?.institution ?? '');
    _profileUser = user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboard();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _institutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSavingProfile = true);
    final response = await auth.updateProfile(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      institution: _institutionCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSavingProfile = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'প্রোফাইল আপডেট হয়েছে'
              : response.message ?? 'আপডেট ব্যর্থ হয়েছে',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildDashboard(auth, admin)
            : _currentIndex == 1
            ? _buildUsersTab(admin)
            : _currentIndex == 2
            ? _buildReportsTab(admin)
            : _currentIndex == 3
            ? _buildPackagesTab(admin)
            : _buildSettingsTab(auth),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(top: BorderSide(color: const Color(0xFFDCE5EF))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'ড্যাশবোর্ড',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'ব্যবহারকারী',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'রিপোর্ট',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_rounded),
              label: 'প্যাকেজ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'সেটিংস',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(AuthProvider auth, AdminProvider admin) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => admin.loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'অ্যাডমিন প্যানেল',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.user?.name ?? 'অ্যাডমিন',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accentOrange, Color(0xFFFF6B42)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // System overview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16213E), Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withAlpha(51)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monitor_heart, color: AppTheme.accentTeal),
                      SizedBox(width: 8),
                      Text(
                        'সিস্টেম ওভারভিউ',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'সবকিছু স্বাভাবিকভাবে চলছে',
                    style: TextStyle(
                      color: AppTheme.accentTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                StatCard(
                  icon: Icons.people_rounded,
                  label: 'মোট ব্যবহারকারী',
                  value: '${admin.dashboardData?['total_users'] ?? 0}',
                  iconColor: AppTheme.primaryColor,
                ),
                StatCard(
                  icon: Icons.school_rounded,
                  label: 'মোট শিক্ষার্থী',
                  value: '${admin.dashboardData?['total_students'] ?? 0}',
                  iconColor: AppTheme.accentTeal,
                ),
                StatCard(
                  icon: Icons.person_search_rounded,
                  label: 'ইন্সট্রাক্টর',
                  value: '${admin.dashboardData?['total_instructors'] ?? 0}',
                  iconColor: AppTheme.accentOrange,
                ),
                StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'মোট কোর্স',
                  value: '${admin.dashboardData?['total_courses'] ?? 0}',
                  iconColor: AppTheme.accentPink,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'দ্রুত অ্যাকশন',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            EduCard(
              onTap: () => setState(() => _currentIndex = 1),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যবহারকারী ম্যানেজ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'ব্যবহারকারীদের যোগ, মুছুন বা সম্পাদনা',
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

  Widget _buildUsersTab(AdminProvider admin) {
    if (!admin.usersLoaded && !admin.isUsersLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        admin.loadUsers();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 0),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Text(
                'ব্যবহারকারী',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showCreateUserDialog(admin),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                tooltip: 'নতুন ব্যবহারকারী যোগ করুন',
              ),
            ],
          ),
        ),
        Expanded(
          child: admin.isUsersLoading || !admin.usersLoaded
              ? const LoadingIndicator()
              : admin.users.isEmpty
              ? admin.usersError != null
                  ? _buildUsersErrorState(admin)
                  : const EmptyState(
                      icon: Icons.people_rounded,
                      title: 'কোনো ব্যবহারকারী নেই',
                    )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: admin.users.length,
                  itemBuilder: (context, index) {
                    final user = admin.users[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EduCard(
                        onTap: () => _showUserDetailsDialog(user),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _roleColor(user.role).withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: _roleColor(user.role),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    user.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _roleColor(user.role).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _roleName(user.role),
                                style: TextStyle(
                                  color: _roleColor(user.role),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            PopupMenuButton(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              color: AppTheme.cardColor,
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('মুছুন'),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'delete' && user.id != null) {
                                  admin.deleteUser(user.id!);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUsersErrorState(AdminProvider admin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.accentOrange),
            const SizedBox(height: 12),
            const Text('ব্যবহারকারীদের তথ্য লোড করা যায়নি'),
            const SizedBox(height: 8),
            Text(admin.usersError!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: admin.isUsersLoading ? null : () => admin.loadUsers(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateUserDialog(AdminProvider admin) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final institutionCtrl = TextEditingController();
    var role = 'student';
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('নতুন ব্যবহারকারী'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'নাম *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'নাম দিন'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ইমেইল *',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ইমেইল দিন';
                        }
                        if (!value.contains('@')) return 'সঠিক ইমেইল দিন';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'পাসওয়ার্ড *',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষর হতে হবে'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: 'রোল *',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('শিক্ষার্থী'),
                        ),
                        DropdownMenuItem(
                          value: 'instructor',
                          child: Text('শিক্ষক / ইন্সট্রাক্টর'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('অ্যাডমিন'),
                        ),
                      ],
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => role = value);
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'ফোন',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: institutionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'প্রতিষ্ঠান',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('বাতিল'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      final messenger = ScaffoldMessenger.of(this.context);
                      final response = await admin.createUser({
                        'name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'password': passwordCtrl.text,
                        'role': role,
                        'phone': phoneCtrl.text.trim(),
                        'institution': institutionCtrl.text.trim(),
                      });
                      if (!mounted || !dialogContext.mounted) return;
                      if (response.success) {
                        Navigator.pop(dialogContext);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('ব্যবহারকারী তৈরি হয়েছে'),
                          ),
                        );
                      } else {
                        setDialogState(() => isSubmitting = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              response.message ??
                                  'ব্যবহারকারী তৈরি ব্যর্থ হয়েছে',
                            ),
                          ),
                        );
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('তৈরি করুন'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    phoneCtrl.dispose();
    institutionCtrl.dispose();
  }

  void _showUserDetailsDialog(user) {
    final roleColor = _roleColor(user.role);
    final roleName = _roleName(user.role);
    final joinDate = user.createdAt != null
        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
        : 'অজানা';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: roleColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(ctx).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: roleColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roleName,
                style: TextStyle(
                  color: roleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _userDetailRow(Icons.email_outlined, 'ইমেইল', user.email),
            _userDetailRow(
              Icons.phone_outlined,
              'ফোন',
              (user.phone != null && user.phone!.isNotEmpty)
                  ? user.phone!
                  : 'যোগ করা হয়নি',
            ),
            _userDetailRow(
              Icons.account_balance_outlined,
              'প্রতিষ্ঠান',
              (user.institution != null && user.institution!.isNotEmpty)
                  ? user.institution!
                  : 'যোগ করা হয়নি',
            ),
            _userDetailRow(
              Icons.calendar_today_outlined,
              'যোগদান',
              joinDate,
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বন্ধ করুন'),
          ),
        ],
      ),
    );
  }

  Widget _userDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBugReportsDialog(AdminProvider admin) {
    final reports = List<Map<String, dynamic>>.from(
      ((admin.reportsData?['bug_reports'] as List<dynamic>?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Bug Reports'),
          content: SizedBox(
            width: 560,
            child: reports.isEmpty
                ? const Text('No bug reports submitted yet.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (_, index) {
                      final report = reports[index];
                      final id = report['id'] as int?;
                      final status = report['status'] ?? 'open';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['title'] as String? ?? 'Untitled report',
                            style: Theme.of(dialogContext).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(report['description'] as String? ?? ''),
                          const SizedBox(height: 8),
                          Text(
                            'Reported by: ${report['reporter_name'] ?? 'Unknown'} '
                            '(${report['reporter_role'] ?? 'user'})',
                            style: Theme.of(dialogContext).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children: [
                              _statusAction('Unsolved', 'open', status, id, admin, setDialogState, report),
                              _statusAction('Working', 'in_progress', status, id, admin, setDialogState, report),
                              _statusAction('Solved', 'resolved', status, id, admin, setDialogState, report),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusAction(
    String label,
    String value,
    dynamic current,
    int? id,
    AdminProvider admin,
    StateSetter setDialogState,
    Map<String, dynamic> report,
  ) {
    final selected = current == value;
    return TextButton(
      onPressed: selected || id == null
          ? null
          : () async {
              if (await admin.updateBugReportStatus(id, value)) {
                setDialogState(() => report['status'] = value);
              }
            },
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppTheme.primaryColor.withAlpha(30) : null,
      ),
      child: Text(label),
    );
  }

  void _showBugReports(AdminProvider admin) {
    final reports = (admin.reportsData?['bug_reports'] as List<dynamic>?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.bug_report_rounded, color: AppTheme.accentOrange),
            SizedBox(width: 10),
            Text('Bug Reports'),
          ],
        ),
        content: SizedBox(
          width: 560,
          child: reports.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No bug reports submitted yet.'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (_, index) {
                    final report = reports[index] as Map<String, dynamic>;
                    final reporter = report['reporter_name'] ?? 'Unknown user';
                    final role = report['reporter_role'] ?? 'user';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['title'] as String? ?? 'Untitled report',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(report['description'] as String? ?? ''),
                        const SizedBox(height: 10),
                        Text(
                          '$reporter • $role • ${report['status'] ?? 'open'}',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab(AdminProvider admin) {
    if (!admin.reportsLoaded && !admin.isReportsLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        admin.loadReports();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Text(
                'রিপোর্ট ও বিশ্লেষণ',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),
          admin.isReportsLoading || !admin.reportsLoaded
              ? const LoadingIndicator()
              : admin.reportsError != null
              ? _buildReportsErrorState(admin)
              : Column(
                  children: [
                    EduCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.trending_up_rounded,
                                color: AppTheme.accentTeal,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'মোট রেজিস্ট্রেশন',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${admin.reportsData?['total_registrations'] ?? 0}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.accentTeal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EduCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.quiz_rounded,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'মোট টেস্ট সম্পন্ন',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${admin.reportsData?['total_tests_completed'] ?? 0}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    EduCard(
                      onTap: () => _showBugReportsDialog(admin),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.bug_report_rounded,
                                color: AppTheme.accentOrange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'বাগ রিপোর্ট',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${admin.reportsData?['total_bug_reports'] ?? 0}',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: AppTheme.accentOrange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildReportsErrorState(AdminProvider admin) {
    return EduCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 42, color: AppTheme.accentOrange),
          const SizedBox(height: 12),
          Text(admin.reportsError!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: admin.isReportsLoading ? null : () => admin.loadReports(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab(AdminProvider admin) {
    if (!admin.packagesLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => admin.loadPackages());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: Text('প্যাকেজ ম্যানেজমেন্ট', style: Theme.of(context).textTheme.headlineLarge)),
            IconButton(onPressed: () => _showPackageDialog(admin), icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor, size: 28)),
          ]),
        ),
        Expanded(
          child: admin.packages.isEmpty
              ? const EmptyState(icon: Icons.workspace_premium_outlined, title: 'কোনো প্যাকেজ নেই', subtitle: 'উপরে + চাপ দিয়ে প্যাকেজ যোগ করুন')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: admin.packages.length,
                  itemBuilder: (context, index) {
                    final plan = admin.packages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EduCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(plan.title, style: Theme.of(context).textTheme.titleMedium),
                            Text('${plan.price} ${plan.period}', style: Theme.of(context).textTheme.bodyMedium),
                            Text('${plan.features.length}টি সুবিধা', style: Theme.of(context).textTheme.bodySmall),
                          ])),
                            IconButton(onPressed: () => _showPackageDialog(admin, plan), icon: const Icon(Icons.edit_outlined)),
                            IconButton(onPressed: () async { await admin.deletePackage(plan.id); }, icon: const Icon(Icons.delete_outline)),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showPackageDialog(AdminProvider admin, [dynamic existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final subtitle = TextEditingController(text: existing?.subtitle ?? '');
    final price = TextEditingController(text: existing?.price ?? '');
    final period = TextEditingController(text: existing?.period ?? '');
    final features = TextEditingController(text: existing == null ? '' : existing.features.join(', '));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন প্যাকেজ যোগ করুন'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'প্যাকেজের নাম')),
          TextField(controller: subtitle, decoration: const InputDecoration(labelText: 'সংক্ষিপ্ত বিবরণ')),
          TextField(controller: price, decoration: const InputDecoration(labelText: 'মূল্য')),
          TextField(controller: period, decoration: const InputDecoration(labelText: 'মেয়াদ')),
          TextField(controller: features, decoration: const InputDecoration(labelText: 'সুবিধা (কমা দিয়ে লিখুন)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
          FilledButton(onPressed: () async {
            if (title.text.trim().isEmpty || price.text.trim().isEmpty) return;
            final data = {
              'title': title.text.trim(), 'subtitle': subtitle.text.trim(), 'price': price.text.trim(),
              'period': period.text.trim(), 'features': features.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
            };
            final saved = existing == null
                ? await admin.createPackage(data)
                : await admin.updatePackage(existing.id, data);
            if (ctx.mounted) Navigator.pop(ctx, saved);
          }, child: const Text('সংরক্ষণ')),
        ],
      ),
    );
    title.dispose(); subtitle.dispose(); price.dispose(); period.dispose(); features.dispose();
    if (ok == true && mounted) setState(() {});
  }

  Widget _buildSettingsTab(AuthProvider auth) {
    _syncProfileControllers(auth.user);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentIndex = 2),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'আগের পেজে ফিরুন',
              ),
              Text('সেটিংস', style: Theme.of(context).textTheme.headlineLarge),
              const Spacer(),
              TextButton(
                onPressed: () {
                  openGreenEarthWebsite();
                },
                child: const Text('আমাদের সম্পর্কে'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.accentOrange, Color(0xFFFF6B42)],
              ),
            ),
            child: Text(
              (auth.user?.name ?? 'A').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auth.user?.name ?? '',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            auth.user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'অ্যাডমিন',
              style: TextStyle(
                color: AppTheme.accentOrange,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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
                  initialValue: auth.user?.email,
                  readOnly: true,
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
                    prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: EduButton(
                    text: 'আপডেট করুন',
                    icon: Icons.save_rounded,
                    isLoading: _isSavingProfile,
                    onPressed: _isSavingProfile
                        ? null
                        : () => _saveProfile(auth),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: EduButton(
              text: 'লগআউট',
              isOutlined: true,
              icon: Icons.logout_rounded,
              onPressed: () => _handleLogout(auth),
            ),
          ),
        ],
      ),
    );
  }

  void _syncProfileControllers(User? user) {
    if (identical(_profileUser, user)) return;
    _profileUser = user;
    _nameCtrl.value = TextEditingValue(
      text: user?.name ?? '',
      selection: TextSelection.collapsed(offset: (user?.name ?? '').length),
    );
    _phoneCtrl.value = TextEditingValue(
      text: user?.phone ?? '',
      selection: TextSelection.collapsed(offset: (user?.phone ?? '').length),
    );
    _institutionCtrl.value = TextEditingValue(
      text: user?.institution ?? '',
      selection: TextSelection.collapsed(offset: (user?.institution ?? '').length),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.accentOrange;
      case 'instructor':
        return AppTheme.accentTeal;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _roleName(String role) {
    switch (role) {
      case 'admin':
        return 'অ্যাডমিন';
      case 'instructor':
        return 'ইন্সট্রাক্টর';
      default:
        return 'শিক্ষার্থী';
    }
  }
}
