import '../../core/errors/failures.dart';
import '../datasources/announcement_remote_datasource.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  AnnouncementRepository({required this.remoteDataSource});

  Future<List<AnnouncementModel>> getMyAnnouncements({int? moduleId}) async {
    try {
      return await remoteDataSource.getMyAnnouncements(moduleId: moduleId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des annonces: ${e.toString()}');
    }
  }

  Future<List<AnnouncementModel>> getAnnouncements({
    int? moduleId,
    String? priority,
  }) async {
    try {
      return await remoteDataSource.getAnnouncements(
        moduleId: moduleId,
        priority: priority,
      );
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des annonces: ${e.toString()}');
    }
  }

  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createAnnouncement(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création de l\'annonce: ${e.toString()}');
    }
  }
}

