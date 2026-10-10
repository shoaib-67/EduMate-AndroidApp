import 'package:flutter/material.dart';

import 'common_widgets.dart';

class ProfileForm extends StatelessWidget {
  const ProfileForm({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.institutionController,
    required this.email,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController institutionController;
  final String? email;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return EduCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'নাম',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: email,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'ইমেইল',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'ফোন',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: institutionController,
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
              isLoading: isSaving,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}
