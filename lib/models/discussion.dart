class Discussion {
  final int? id;
  final String title;
  final String content;
  final String? authorName;
  final int? authorId;
  final String? authorRole;
  final int? replyCount;
  final List<DiscussionReply>? replies;
  final DateTime? createdAt;

  Discussion({
    this.id,
    required this.title,
    required this.content,
    this.authorName,
    this.authorId,
    this.authorRole,
    this.replyCount,
    this.replies,
    this.createdAt,
  });

  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorName: json['author_name'] as String?,
      authorId: json['author_id'] as int?,
      authorRole: json['author_role'] as String?,
      replyCount: json['reply_count'] as int?,
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => DiscussionReply.fromJson(r as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

class DiscussionReply {
  final int? id;
  final String content;
  final String? authorName;
  final int? authorId;
  final DateTime? createdAt;

  DiscussionReply({
    this.id,
    required this.content,
    this.authorName,
    this.authorId,
    this.createdAt,
  });

  factory DiscussionReply.fromJson(Map<String, dynamic> json) {
    return DiscussionReply(
      id: json['id'] as int?,
      content: json['content'] as String? ?? '',
      authorName: json['author_name'] as String?,
      authorId: json['author_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}
