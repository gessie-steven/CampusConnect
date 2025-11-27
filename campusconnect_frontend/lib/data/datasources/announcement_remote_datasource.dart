import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/announcement_model.dart';

class AnnouncementRemoteDataSource {
  final Dio dio;

  AnnouncementRemoteDataSource({required this.dio});

  Future<List<AnnouncementModel>> getMyAnnouncements({int? moduleId}) async {
    try {
      final queryParams = moduleId != null ? {'module': moduleId} : null;
      final response = await dio.get(
        '${AppConstants.baseUrl}/announcements/my/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des annonces');
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

  Future<List<AnnouncementModel>> getAnnouncements({
    int? moduleId,
    String? priority,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (moduleId != null) queryParams['module'] = moduleId;
      if (priority != null) queryParams['priority'] = priority;

      final response = await dio.get(
        '${AppConstants.baseUrl}/announcements/',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => AnnouncementModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des annonces');
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

  Future<AnnouncementModel> createAnnouncement(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/announcements/',
        data: data,
      );

      if (response.statusCode == 201) {
        return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la création de l\'annonce');
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
        throw ServerFailure('Erreur lors de la création de l\'annonce');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}

