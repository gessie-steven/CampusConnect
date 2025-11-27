import '../../core/errors/failures.dart';
import '../datasources/session_remote_datasource.dart';
import '../models/course_session_model.dart';

class SessionRepository {
  final SessionRemoteDataSource remoteDataSource;

  SessionRepository({required this.remoteDataSource});

  Future<List<CourseSessionModel>> getMySchedule({
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      return await remoteDataSource.getMySchedule(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération de l\'emploi du temps: ${e.toString()}');
    }
  }

  Future<List<CourseSessionModel>> getSessions({
    int? moduleId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      return await remoteDataSource.getSessions(
        moduleId: moduleId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des sessions: ${e.toString()}');
    }
  }

  Future<CourseSessionModel> createSession(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createSession(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création de la session: ${e.toString()}');
    }
  }
}

