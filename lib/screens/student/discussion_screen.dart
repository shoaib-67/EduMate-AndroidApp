import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/discussion.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

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

  Future<void> _showCreateDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    await showModalBottomSheet<void>(
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
                    final created = await context
                        .read<StudentProvider>()
                        .createDiscussion(titleCtrl.text, contentCtrl.text);
                    if (!ctx.mounted) return;
                    if (created) {
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'আলোচনা পোস্ট করা যায়নি। আবার চেষ্টা করুন।',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
    titleCtrl.dispose();
    contentCtrl.dispose();
  }

  Future<void> _openDiscussion(Discussion discussion) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: _DiscussionDetailsSheet(discussion: discussion),
      ),
    );
    if (mounted) context.read<StudentProvider>().loadDiscussions();
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();

    return Scaffold(
      bottomNavigationBar: const RoleBottomNavigation(
        role: AppRole.student,
        selectedIndex: 0,
      ),
      appBar: AppBar(
        title: const Text('আলোচনা'),
        actions: [
          IconButton(
            tooltip: 'আলোচনা রিফ্রেশ করুন',
            onPressed: student.isDiscussionsLoading
                ? null
                : student.loadDiscussions,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: student.isDiscussionsLoading || !student.discussionsLoaded
          ? const LoadingIndicator(message: 'লোড হচ্ছে...')
          : student.discussions.isEmpty
          ? EmptyState(
              icon: Icons.forum_rounded,
              title: 'কোনো আলোচনা নেই',
              subtitle: 'প্রথম আলোচনা শুরু করুন!',
              actionText: 'আলোচনা শুরু করুন',
              onAction: _showCreateDialog,
            )
          : RefreshIndicator(
              onRefresh: student.loadDiscussions,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: student.discussions.length,
                itemBuilder: (context, index) {
                  final discussion = student.discussions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EduCard(
                      onTap: () => _openDiscussion(discussion),
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

class _DiscussionDetailsSheet extends StatefulWidget {
  const _DiscussionDetailsSheet({required this.discussion});

  final Discussion discussion;

  @override
  State<_DiscussionDetailsSheet> createState() =>
      _DiscussionDetailsSheetState();
}

class _DiscussionDetailsSheetState extends State<_DiscussionDetailsSheet> {
  final _replyController = TextEditingController();
  late Future<Discussion?> _details;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _details = context.read<StudentProvider>().getDiscussion(
      widget.discussion.id!,
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _details = context.read<StudentProvider>().getDiscussion(
        widget.discussion.id!,
      );
    });
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _sending) return;
    setState(() => _sending = true);
    final sent = await context.read<StudentProvider>().replyToDiscussion(
      widget.discussion.id!,
      content,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent) {
      _replyController.clear();
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উত্তর পাঠানো যায়নি। আবার চেষ্টা করুন।')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'আলোচনা',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'রিফ্রেশ করুন',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'বন্ধ করুন',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<Discussion?>(
                  future: _details,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LoadingIndicator();
                    }
                    final detail = snapshot.data;
                    if (detail == null) {
                      return EmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: 'আলোচনা লোড করা যায়নি',
                        actionText: 'আবার চেষ্টা করুন',
                        onAction: _refresh,
                      );
                    }
                    return ListView(
                      children: [
                        Text(
                          detail.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detail.authorName ?? 'অজ্ঞাত',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Text(detail.content),
                        const Divider(height: 32),
                        Text(
                          'উত্তর (${detail.replies?.length ?? 0})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (detail.replies?.isEmpty ?? true)
                          Text(
                            'এখনো কোনো উত্তর নেই।',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        for (final reply
                            in detail.replies ?? <DiscussionReply>[])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EduCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reply.authorName ?? 'অজ্ঞাত',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(reply.content),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replyController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'আপনার উত্তর',
                  hintText: 'উত্তর লিখুন...',
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: EduButton(
                  text: 'উত্তর পাঠান',
                  icon: Icons.send_rounded,
                  isLoading: _sending,
                  onPressed: _sendReply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
