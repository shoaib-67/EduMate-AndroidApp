import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/package_plan.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ফিচার প্যাকেজ')),
      body: FutureBuilder<List<PackagePlan>>(
        future: context.read<StudentProvider>().getPackages(),
        builder: (context, snapshot) {
          final managedPackages = snapshot.data ?? [];
          return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'আপনার প্রস্তুতির জন্য\nউপযুক্ত প্ল্যান বেছে নিন',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'শুরু করার জন্য ফ্রি, ধারাবাহিক অনুশীলনের জন্য ১ মাস, আর গভীর প্রস্তুতির জন্য ৩ মাস।',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            ...managedPackages.map(
              (plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PlanCard(
                  title: plan.title,
                  subtitle: plan.subtitle,
                  price: plan.price,
                  period: plan.period,
                  features: plan.features,
                  buttonText: 'প্যাকেজ নিন',
                  color: AppTheme.primaryColor,
                  isPopular: false,
                  onTap: () {},
                ),
              ),
            ),

            // Free plan
            _PlanCard(
              title: 'ফ্রি প্ল্যান',
              subtitle: 'শুরু করুন বিনামূল্যে',
              price: '৳০',
              period: '',
              features: const [
                'বেসিক মক টেস্ট অ্যাক্সেস',
                'নির্বাচিত ফ্রি PDF নোট',
                'দৈনিক স্টাডি রিমাইন্ডার',
              ],
              buttonText: 'ফ্রি শুরু করুন',
              color: AppTheme.textSecondary,
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // 1 Month Plan
            _PlanCard(
              title: '১ মাসের প্ল্যান',
              subtitle: 'দ্রুত উন্নতির জন্য',
              price: '৳৪৯৯',
              period: '/মাস',
              features: const [
                'সকল মক টেস্ট আনলিমিটেড',
                'প্রিমিয়াম ক্লাস কনটেন্ট অ্যাক্সেস',
                'পারফরম্যান্স অ্যানালিটিক্স রিপোর্ট',
              ],
              buttonText: '১ মাস নিন',
              color: AppTheme.primaryColor,
              isPopular: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // 3 Month Plan
            _PlanCard(
              title: '৩ মাসের প্ল্যান',
              subtitle: 'সেরা ভ্যালু প্যাকেজ',
              price: '৳১২৯৯',
              period: '/৩ মাস',
              features: const [
                '১ মাসের সব ফিচার অন্তর্ভুক্ত',
                'ব্যাচভিত্তিক প্রিমিয়াম পেইড ক্লাস',
                'প্রায়োরিটি সাপোর্ট ও গাইডেন্স',
              ],
              buttonText: '৩ মাস নিন',
              color: AppTheme.accentTeal,
              onTap: () {},
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
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final List<String> features;
  final String buttonText;
  final Color color;
  final bool isPopular;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    required this.features,
    required this.buttonText,
    required this.color,
    this.isPopular = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return EduCard(
      hasGradientBorder: isPopular,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'জনপ্রিয়',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    period,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 18),
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
            child: isPopular
                ? EduButton(text: buttonText, onPressed: onTap)
                : EduButton(
                    text: buttonText,
                    isOutlined: true,
                    onPressed: onTap,
                  ),
          ),
        ],
      ),
    );
  }
}
