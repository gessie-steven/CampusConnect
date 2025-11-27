class CourseSessionModel {
  final int id;
  final int moduleId;
  final String? moduleCode;
  final String? moduleName;
  final int? teacherId;
  final String? teacherName;
  final String? teacherUsername;
  final String? title;
  final String sessionType;
  final String? sessionTypeDisplay;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int? durationMinutes;
  final String? location;
  final bool isOnline;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CourseSessionModel({
    required this.id,
    required this.moduleId,
    this.moduleCode,
    this.moduleName,
    this.teacherId,
    this.teacherName,
    this.teacherUsername,
    this.title,
    required this.sessionType,
    this.sessionTypeDisplay,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    this.location,
    required this.isOnline,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseSessionModel.fromJson(Map<String, dynamic> json) {
    return CourseSessionModel(
      id: json['id'] as int,
      moduleId: json['module'] as int,
      moduleCode: json['module_code'] as String?,
      moduleName: json['module_name'] as String?,
      teacherId: json['teacher'] as int?,
      teacherName: json['teacher_name'] as String?,
      teacherUsername: json['teacher_username'] as String?,
      title: json['title'] as String?,
      sessionType: json['session_type'] as String,
      sessionTypeDisplay: json['session_type_display'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationMinutes: json['duration'] as int?,
      location: json['location'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      description: json['description'] as String?,
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
      'session_type': sessionType,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'location': location,
      'is_online': isOnline,
      'description': description,
    };
  }
}

