import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppRole { student, instructor, admin }

class RoleBottomNavigation extends StatelessWidget {
  const RoleBottomNavigation({
    super.key,
    required this.role,
    required this.selectedIndex,
    this.onTap,
    this.confirmMessage,
  });

  final AppRole role;
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final String? confirmMessage;

  static const _studentItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'ড্যাশবোর্ড',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_rounded),
      label: 'কোর্স',
    ),
    BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'মক টেস্ট'),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics_rounded),
      label: 'অগ্রগতি',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_rounded),
      label: 'প্রোফাইল',
    ),
  ];

  static const _instructorItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'ড্যাশবোর্ড',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_rounded),
      label: 'কোর্স',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_rounded),
      label: 'শিক্ষার্থী',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_rounded),
      label: 'প্রোফাইল',
    ),
  ];

  static const _adminItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'ড্যাশবোর্ড',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.people_rounded),
      label: 'ব্যবহারকারী',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu_book_rounded),
      label: 'কোর্স',
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
  ];

  Future<void> _navigate(BuildContext context, int index) async {
    if (confirmMessage != null) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave this page?'),
          content: Text(confirmMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (shouldLeave != true || !context.mounted) return;
    }
    final route = switch (role) {
      AppRole.student => '/student',
      AppRole.instructor => '/instructor',
      AppRole.admin => '/admin',
    };
    Navigator.of(context)
        .pushNamedAndRemoveUntil(route, (route) => false, arguments: index);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }
    final items = switch (role) {
      AppRole.student => _studentItems,
      AppRole.instructor => _instructorItems,
      AppRole.admin => _adminItems,
    };
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(top: BorderSide(color: Color(0xFFDCE5EF))),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedFontSize: role == AppRole.admin ? 10 : 12,
        unselectedFontSize: role == AppRole.admin ? 10 : 12,
        iconSize: role == AppRole.admin ? 22 : 24,
        currentIndex: selectedIndex,
        onTap: onTap ?? (index) => _navigate(context, index),
        items: items,
      ),
    );
  }
}
