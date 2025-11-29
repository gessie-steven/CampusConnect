import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../datasources/resource_remote_datasource.dart';
import '../models/course_resource_model.dart';

class ResourceRepository {
  final ResourceRemoteDataSource remoteDataSource;

  ResourceRepository({required this.remoteDataSource});

  Future<List<CourseResourceModel>> getResources({int? moduleId}) async {
    try {
      return await remoteDataSource.getResources(moduleId: moduleId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des ressources: ${e.toString()}');
    }
  }

  Future<CourseResourceModel> createResource(FormData formData) async {
    try {
      return await remoteDataSource.createResource(formData);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de l\'upload de la ressource: ${e.toString()}');
    }
  }

  Future<CourseResourceModel> createResourceWithUrl(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createResourceWithUrl(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création de la ressource: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> downloadResource(int id) async {
    try {
      return await remoteDataSource.downloadResource(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors du téléchargement: ${e.toString()}');
    }
  }
}

