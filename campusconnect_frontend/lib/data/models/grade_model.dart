class GradeModel {
  final int id;
  final int studentId;
  final String? studentName;
  final String? studentUsername;
  final String? studentEmail;
  final int moduleId;
  final String? moduleCode;
  final String? moduleName;
  final String gradeType;
  final String? gradeTypeDisplay;
  final double grade;
  final double maxGrade;
  final double? percentage;
  final String? letterGrade;
  final String? comment;
  final int? gradedById;
  final String? gradedByName;
  final String? gradedByUsername;
  final DateTime gradedDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GradeModel({
    required this.id,
    required this.studentId,
    this.studentName,
    this.studentUsername,
    this.studentEmail,
    required this.moduleId,
    this.moduleCode,
    this.moduleName,
    required this.gradeType,
    this.gradeTypeDisplay,
    required this.grade,
    required this.maxGrade,
    this.percentage,
    this.letterGrade,
    this.comment,
    this.gradedById,
    this.gradedByName,
    this.gradedByUsername,
    required this.gradedDate,
    this.createdAt,
    this.updatedAt,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    // Helper function to parse number from string or num
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.parse(value);
      }
      throw FormatException('Cannot parse $value as double');
    }

    return GradeModel(
      id: json['id'] as int,
      studentId: json['student'] as int,
      studentName: json['student_name'] as String?,
      studentUsername: json['student_username'] as String?,
      studentEmail: json['student_email'] as String?,
      moduleId: json['module'] as int,
      moduleCode: json['module_code'] as String?,
      moduleName: json['module_name'] as String?,
      gradeType: json['grade_type'] as String,
      gradeTypeDisplay: json['grade_type_display'] as String?,
      grade: parseDouble(json['grade']),
      maxGrade: parseDouble(json['max_grade']),
      percentage: json['percentage'] != null
          ? parseDouble(json['percentage'])
          : null,
      letterGrade: json['letter_grade'] as String?,
      comment: json['comment'] as String?,
      gradedById: json['graded_by'] as int?,
      gradedByName: json['graded_by_name'] as String?,
      gradedByUsername: json['graded_by_username'] as String?,
      gradedDate: DateTime.parse(json['graded_date'] as String),
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
      'grade_type': gradeType,
      'grade': grade,
      'max_grade': maxGrade,
      'comment': comment,
    };
  }
}

