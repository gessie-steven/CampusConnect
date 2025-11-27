class CourseResourceModel {
  final int id;
  final int moduleId;
  final String? moduleCode;
  final String? moduleName;
  final String title;
  final String? description;
  final String resourceType;
  final String? resourceTypeDisplay;
  final String? fileUrl;
  final String? externalUrl;
  final int? uploadedById;
  final String? uploadedByName;
  final String? uploadedByUsername;
  final bool isPublic;
  final int? fileSize;
  final String? fileSizeHuman;
  final int downloadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseResourceModel({
    required this.id,
    required this.moduleId,
    this.moduleCode,
    this.moduleName,
    required this.title,
    this.description,
    required this.resourceType,
    this.resourceTypeDisplay,
    this.fileUrl,
    this.externalUrl,
    this.uploadedById,
    this.uploadedByName,
    this.uploadedByUsername,
    required this.isPublic,
    this.fileSize,
    this.fileSizeHuman,
    required this.downloadCount,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseResourceModel.fromJson(Map<String, dynamic> json) {
    return CourseResourceModel(
      id: json['id'] as int,
      moduleId: json['module'] as int,
      moduleCode: json['module_code'] as String?,
      moduleName: json['module_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      resourceType: json['resource_type'] as String,
      resourceTypeDisplay: json['resource_type_display'] as String?,
      fileUrl: json['file_url'] as String?,
      externalUrl: json['external_url'] as String?,
      uploadedById: json['uploaded_by'] as int?,
      uploadedByName: json['uploaded_by_name'] as String?,
      uploadedByUsername: json['uploaded_by_username'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      fileSize: json['file_size'] as int?,
      fileSizeHuman: json['file_size_human'] as String?,
      downloadCount: json['download_count'] as int? ?? 0,
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
      'module': moduleId,
      'title': title,
      'description': description,
      'resource_type': resourceType,
      'external_url': externalUrl,
      'is_public': isPublic,
    };
  }
}

