import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/course_resource_model.dart';

class ResourceRemoteDataSource {
  final Dio dio;

  ResourceRemoteDataSource({required this.dio});

  Future<List<CourseResourceModel>> getResources({int? moduleId}) async {
    try {
      final queryParams = moduleId != null ? {'module': moduleId} : null;
      final response = await dio.get(
        '${AppConstants.baseUrl}/resources/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => CourseResourceModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des ressources');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerFailure('Erreur serveur: ${e.response?.statusCode}');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<CourseResourceModel> createResource(FormData formData) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/resources/',
        data: formData,
      );

      if (response.statusCode == 201) {
        return CourseResourceModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de l\'upload de la ressource');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errors = <String, String>{};
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors[key] = value.first as String;
            }
          });
          if (errors.isNotEmpty) {
            throw ValidationFailure(errors.values.first);
          }
        }
        throw ServerFailure('Erreur lors de l\'upload de la ressource');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> downloadResource(int id) async {
    try {
      final response = await dio.get('${AppConstants.baseUrl}/resources/$id/download/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerFailure('Erreur lors du téléchargement');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerFailure('Erreur lors du téléchargement');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}

