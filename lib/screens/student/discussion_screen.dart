import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadDiscussions();
    });
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('নতুন আলোচনা', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'শিরোনাম',
                hintText: 'আলোচনার বিষয়',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'বিস্তারিত',
                hintText: 'আপনার প্রশ্ন বা মতামত লিখুন...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: EduButton(
                text: 'পোস্ট করুন',
                icon: Icons.send_rounded,
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty &&
                      contentCtrl.text.isNotEmpty) {
                    await context.read<StudentProvider>().createDiscussion(
                      titleCtrl.text,
                      contentCtrl.text,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('আলোচনা')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: student.isDiscussionsLoading || !student.discussionsLoaded
          ? const LoadingIndicator(message: 'লোড হচ্ছে...')
          : student.discussions.isEmpty
          ? const EmptyState(
              icon: Icons.forum_rounded,
              title: 'কোনো আলোচনা নেই',
              subtitle: 'প্রথম আলোচনা শুরু করুন!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: student.discussions.length,
              itemBuilder: (context, index) {
                final discussion = student.discussions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EduCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (discussion.authorName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discussion.authorName ?? 'অজ্ঞাত',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  if (discussion.createdAt != null)
                                    Text(
                                      _formatDate(discussion.createdAt!),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          discussion.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          discussion.content,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${discussion.replyCount ?? 0} উত্তর',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    if (diff.inDays < 7) return '${diff.inDays} দিন আগে';
    return '${date.day}/${date.month}/${date.year}';
  }
}
