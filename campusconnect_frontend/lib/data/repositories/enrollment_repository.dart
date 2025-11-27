import '../../core/errors/failures.dart';
import '../datasources/enrollment_remote_datasource.dart';
import '../models/enrollment_model.dart';

class EnrollmentRepository {
  final EnrollmentRemoteDataSource remoteDataSource;

  EnrollmentRepository({required this.remoteDataSource});

  Future<List<EnrollmentModel>> getMyEnrollments() async {
    try {
      return await remoteDataSource.getMyEnrollments();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des inscriptions: ${e.toString()}');
    }
  }

  Future<EnrollmentModel> enrollToModule(int moduleId) async {
    try {
      return await remoteDataSource.enrollToModule(moduleId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  Future<void> unenrollFromModule(int moduleId) async {
    try {
      await remoteDataSource.unenrollFromModule(moduleId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la désinscription: ${e.toString()}');
    }
  }
}

