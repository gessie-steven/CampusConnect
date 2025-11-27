import 'module_model.dart';
import 'user_model.dart';

class EnrollmentModel {
  final int id;
  final int studentId;
  final String? studentName;
  final String? studentUsername;
  final String? studentEmail;
  final int moduleId;
  final String? moduleCode;
  final String? moduleName;
  final DateTime enrollmentDate;
  final bool isActive;
  final double? grade;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EnrollmentModel({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentUsername,
    this.studentEmail,
    required this.moduleId,
    this.moduleCode,
    this.moduleName,
    required this.enrollmentDate,
    required this.isActive,
    this.grade,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: json['id'] as int,
      studentId: json['student'] as int,
      studentName: json['student_name'] as String?,
      studentUsername: json['student_username'] as String?,
      studentEmail: json['student_email'] as String?,
      moduleId: json['module'] as int,
      moduleCode: json['module_code'] as String?,
      moduleName: json['module_name'] as String?,
      enrollmentDate: DateTime.parse(json['enrollment_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      grade: json['grade'] != null
          ? (json['grade'] as num).toDouble()
          : null,
      notes: json['notes'] as String?,
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
      'student': studentId,
      'module': moduleId,
      'enrollment_date': enrollmentDate.toIso8601String(),
      'is_active': isActive,
      'grade': grade,
      'notes': notes,
    };
  }
}

