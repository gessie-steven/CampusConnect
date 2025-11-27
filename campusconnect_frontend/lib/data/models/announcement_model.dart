class AnnouncementModel {
  final int id;
  final int authorId;
  final String? authorName;
  final String? authorUsername;
  final String title;
  final String content;
  final int? moduleId;
  final String? moduleCode;
  final String? moduleName;
  final String priority;
  final String? priorityDisplay;
  final bool isPinned;
  final bool isActive;
  final String? targetAudience;
  final String? targetAudienceDisplay;
  final DateTime publishedDate;
  final DateTime? expiryDate;
  final bool? isExpired;
  final bool? isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AnnouncementModel({
    required this.id,
    required this.authorId,
    this.authorName,
    this.authorUsername,
    required this.title,
    required this.content,
    this.moduleId,
    this.moduleCode,
    this.moduleName,
    required this.priority,
    this.priorityDisplay,
    required this.isPinned,
    required this.isActive,
    this.targetAudience,
    this.targetAudienceDisplay,
    required this.publishedDate,
    this.expiryDate,
    this.isExpired,
    this.isVisible,
    this.createdAt,
    this.updatedAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as int,
      authorId: json['author'] as int,
      authorName: json['author_name'] as String?,
      authorUsername: json['author_username'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      moduleId: json['module'] as int?,
      moduleCode: json['module_code'] as String?,
      moduleName: json['module_name'] as String?,
      priority: json['priority'] as String,
      priorityDisplay: json['priority_display'] as String?,
      isPinned: json['is_pinned'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      targetAudience: json['target_role'] as String?,
      targetAudienceDisplay: json['target_role_display'] as String?,
      publishedDate: DateTime.parse(json['published_date'] as String),
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      isExpired: json['is_expired'] as bool?,
      isVisible: json['is_visible'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': authorId,
      'title': title,
      'content': content,
      'module': moduleId,
      'priority': priority,
      'is_pinned': isPinned,
      'is_active': isActive,
      'target_audience': targetAudience,
      'expiry_date': expiryDate?.toIso8601String(),
    };
  }
}

