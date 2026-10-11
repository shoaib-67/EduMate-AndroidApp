import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/discussion.dart';
import '../../providers/student_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/role_bottom_navigation.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({
    super.key,
    this.isInstructor = false,
    this.courseId,
    this.embedded = false,
  });

  final bool isInstructor;
  final int? courseId;
  final bool embedded;

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  String _query = '';
  List<Discussion> _courseDiscussions = [];
  bool _courseLoading = false;
  bool _courseLoaded = false;
  String? _courseError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadDiscussions();
    });
  }

  Future<void> _loadDiscussions() async {
    if (widget.courseId == null) {
      await context.read<StudentProvider>().loadDiscussions();
      return;
    }
    setState(() {
      _courseLoading = true;
      _courseError = null;
    });
    try {
      final items = await context.read<StudentProvider>().getCourseDiscussions(
        widget.courseId!,
      );
      if (mounted) setState(() => _courseDiscussions = items);
    } catch (_) {
      if (mounted) setState(() => _courseError = 'আলোচনা লোড করা যায়নি');
    } finally {
      if (mounted) {
        setState(() {
          _courseLoading = false;
          _courseLoaded = true;
        });
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final provider = context.read<StudentProvider>();
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateDiscussionSheet(
        onSubmit: (title, content) => widget.courseId == null
            ? provider.createDiscussion(title, content)
            : provider.createCourseDiscussion(widget.courseId!, title, content),
      ),
    );
    if (posted == true && mounted) await _loadDiscussions();
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
    if (mounted) _loadDiscussions();
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<StudentProvider>();
    final canStartDiscussion = !widget.isInstructor || widget.courseId != null;
    final source = widget.courseId == null
        ? student.discussions
        : _courseDiscussions;
    final loading = widget.courseId == null
        ? student.isDiscussionsLoading || !student.discussionsLoaded
        : _courseLoading || !_courseLoaded;
    final query = _query.trim().toLowerCase();
    final discussions = source.where((discussion) {
      return query.isEmpty ||
          discussion.title.toLowerCase().contains(query) ||
          discussion.content.toLowerCase().contains(query) ||
          (discussion.authorName ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      bottomNavigationBar: widget.embedded || widget.isInstructor
          ? null
          : RoleBottomNavigation(role: AppRole.student, selectedIndex: 0),
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Text('আলোচনা'),
              actions: [
                IconButton(
                  tooltip: 'আলোচনা রিফ্রেশ করুন',
                  onPressed: loading ? null : _loadDiscussions,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
      floatingActionButton: !canStartDiscussion || widget.embedded
          ? null
          : FloatingActionButton(
              onPressed: _showCreateDialog,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: Column(
        children: [
          if (widget.embedded && canStartDiscussion)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('এই কোর্সে আলোচনা শুরু করুন'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'আলোচনা খুঁজুন',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const LoadingIndicator(message: 'লোড হচ্ছে...')
                : _courseError != null
                ? EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: _courseError!,
                    actionText: 'আবার চেষ্টা করুন',
                    onAction: _loadDiscussions,
                  )
                : discussions.isEmpty
                ? EmptyState(
                    icon: Icons.forum_rounded,
                    title: query.isEmpty
                        ? 'কোনো আলোচনা নেই'
                        : 'কোনো আলোচনা পাওয়া যায়নি',
                    subtitle: query.isEmpty
                        ? (widget.isInstructor && widget.courseId == null
                              ? 'শিক্ষার্থীরা আলোচনা শুরু করলে এখানে দেখা যাবে'
                              : 'প্রথম আলোচনা শুরু করুন!')
                        : 'অন্য কিছু দিয়ে খুঁজুন',
                    actionText:
                        query.isEmpty && !widget.embedded && canStartDiscussion
                        ? 'আলোচনা শুরু করুন'
                        : null,
                    onAction:
                        query.isEmpty && !widget.embedded && canStartDiscussion
                        ? _showCreateDialog
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: _loadDiscussions,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: discussions.length,
                      itemBuilder: (context, index) {
                        final discussion = discussions[index];
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
                                        color: AppTheme.primaryColor.withAlpha(
                                          25,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          (discussion.authorName?.isNotEmpty ==
                                                      true
                                                  ? discussion.authorName!
                                                  : 'U')
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${discussion.authorName ?? 'অজ্ঞাত'} (${discussion.authorRole == 'instructor' ? 'শিক্ষক' : 'শিক্ষার্থী'})',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          if (discussion.createdAt != null)
                                            Text(
                                              _formatDate(
                                                discussion.createdAt!,
                                              ),
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
                                if (widget.isInstructor &&
                                    widget.courseId == null &&
                                    discussion.courseTitle != null) ...[
                                  Text(
                                    discussion.courseTitle!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  discussion.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
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
          ),
        ],
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

class _CreateDiscussionSheet extends StatefulWidget {
  const _CreateDiscussionSheet({required this.onSubmit});

  final Future<bool> Function(String title, String content) onSubmit;

  @override
  State<_CreateDiscussionSheet> createState() => _CreateDiscussionSheetState();
}

class _CreateDiscussionSheetState extends State<_CreateDiscussionSheet> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শিরোনাম ও বিস্তারিত লিখুন')),
      );
      return;
    }
    if (_posting) return;
    setState(() => _posting = true);
    final created = await widget.onSubmit(title, content);
    if (!mounted) return;
    setState(() => _posting = false);
    if (created) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('আলোচনা পোস্ট করা যায়নি। আবার চেষ্টা করুন।'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
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
          Text(
            'নতুন আলোচনা',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _title,
            maxLength: 180,
            decoration: const InputDecoration(
              labelText: 'শিরোনাম',
              hintText: 'আলোচনার বিষয়',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _content,
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
              isLoading: _posting,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    ),
  );
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
                                    '${reply.authorName ?? 'অজ্ঞাত'} (${reply.authorRole == 'instructor' ? 'শিক্ষক' : 'শিক্ষার্থী'})',
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
