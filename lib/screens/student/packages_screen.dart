import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/package_plan.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  late Future<List<PackagePlan>> _packages;

  @override
  void initState() {
    super.initState();
    _packages = context.read<StudentProvider>().getPackages();
  }

  Future<void> _refresh() async {
    final next = context.read<StudentProvider>().getPackages();
    setState(() {
      _packages = next;
    });
    try {
      await next;
    } catch (_) {
      // FutureBuilder presents the error with a retry action.
    }
  }

  void _showDetails(PackagePlan plan) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${plan.price}${plan.period}',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 20),
                  for (final feature in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppTheme.accentTeal,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(feature)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ঠিক আছে'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.student,
        selectedIndex: 0,
      ),
      appBar: AppBar(
        title: const Text('ফিচার প্যাকেজ'),
        actions: [
          IconButton(
            tooltip: 'প্যাকেজ রিফ্রেশ করুন',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<PackagePlan>>(
        future: _packages,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingIndicator(message: 'প্যাকেজ লোড হচ্ছে...');
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'প্যাকেজ লোড করা যায়নি',
              subtitle: '${snapshot.error}',
              actionText: 'আবার চেষ্টা করুন',
              onAction: _refresh,
            );
          }
          final managedPackages = snapshot.data ?? [];
          if (managedPackages.isEmpty) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'এখন কোনো প্যাকেজ নেই',
              subtitle: 'নতুন প্যাকেজ যোগ হলে এখানে দেখা যাবে।',
              actionText: 'রিফ্রেশ করুন',
              onAction: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'আপনার প্রস্তুতির জন্য\nউপযুক্ত প্ল্যান দেখুন',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'উপলব্ধ প্যাকেজগুলোর সুবিধা ও মূল্য দেখে নিন।',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
                ...managedPackages.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PlanCard(
                      plan: plan,
                      onTap: () => _showDetails(plan),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PackagePlan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return EduCard(
      onTap: onTap,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: AppTheme.primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (plan.period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    plan.period,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: EduButton(
              text: 'বিস্তারিত দেখুন',
              isOutlined: true,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
