import '../../core/errors/failures.dart';
import '../datasources/grade_remote_datasource.dart';
import '../models/grade_model.dart';

class GradeRepository {
  final GradeRemoteDataSource remoteDataSource;

  GradeRepository({required this.remoteDataSource});

  Future<List<GradeModel>> getMyGrades({int? moduleId}) async {
    try {
      return await remoteDataSource.getMyGrades(moduleId: moduleId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des notes: ${e.toString()}');
    }
  }

  Future<List<GradeModel>> getGrades({int? moduleId, int? studentId}) async {
    try {
      return await remoteDataSource.getGrades(moduleId: moduleId, studentId: studentId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des notes: ${e.toString()}');
    }
  }

  Future<GradeModel> createGrade(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createGrade(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création de la note: ${e.toString()}');
    }
  }

  Future<GradeModel> updateGrade(int id, Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.updateGrade(id, data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la mise à jour de la note: ${e.toString()}');
    }
  }
}

