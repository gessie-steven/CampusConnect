class ModuleModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final int? teacherId;
  final String? teacherName;
  final String? teacherUsername;
  final int credits;
  final String? semester;
  final bool isActive;
  final int? maxStudents;
  final int enrolledStudentsCount;
  final bool isFull;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ModuleModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.teacherId,
    this.teacherName,
    this.teacherUsername,
    required this.credits,
    this.semester,
    required this.isActive,
    this.maxStudents,
    required this.enrolledStudentsCount,
    required this.isFull,
    this.createdAt,
    this.updatedAt,
  });

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher'] as int?,
      teacherName: json['teacher_name'] as String?,
      teacherUsername: json['teacher_username'] as String?,
      credits: json['credits'] as int? ?? 0,
      semester: json['semester'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      maxStudents: json['max_students'] as int?,
      enrolledStudentsCount: json['enrolled_students_count'] as int? ?? 0,
      isFull: json['is_full'] as bool? ?? false,
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
      'code': code,
      'name': name,
      'description': description,
      'teacher': teacherId,
      'teacher_name': teacherName,
      'teacher_username': teacherUsername,
      'credits': credits,
      'semester': semester,
      'is_active': isActive,
      'max_students': maxStudents,
      'enrolled_students_count': enrolledStudentsCount,
      'is_full': isFull,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

