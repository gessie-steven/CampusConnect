import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/grade_model.dart';

class GradeRemoteDataSource {
  final Dio dio;

  GradeRemoteDataSource({required this.dio});

  Future<List<GradeModel>> getMyGrades({int? moduleId}) async {
    try {
      final queryParams = moduleId != null ? {'module': moduleId} : null;
      final response = await dio.get(
        'grades/my/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => GradeModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des notes');
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

  Future<List<GradeModel>> getGrades({int? moduleId, int? studentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (moduleId != null) queryParams['module'] = moduleId;
      if (studentId != null) queryParams['student'] = studentId;

      final response = await dio.get(
        'grades/',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => GradeModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des notes');
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

  Future<GradeModel> createGrade(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        'grades/',
        data: data,
      );

      if (response.statusCode == 201) {
        return GradeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la création de la note');
      }
    } on DioException catch (e) {
      print('❌ Erreur Dio lors de la création de la note: ${e.message}');
      if (e.response != null) {
        print('📊 Status code: ${e.response!.statusCode}');
        print('📄 Response data: ${e.response!.data}');
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errors = <String, String>{};
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors[key] = value.first.toString();
              print('⚠️ Erreur champ "$key": ${value.first}');
            } else if (value is String) {
              errors[key] = value;
              print('⚠️ Erreur champ "$key": $value');
            }
          });
          if (errors.isNotEmpty) {
            final errorMessage = errors.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            throw ValidationFailure(errorMessage);
          }
        }
        final errorMessage = errorData is String ? errorData : errorData.toString();
        throw ServerFailure('Erreur lors de la création de la note: $errorMessage');
      } else {
        print('❌ Erreur réseau: ${e.message}');
        throw NetworkFailure('Erreur de réseau: ${e.message}');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      print('❌ Erreur inattendue: ${e.toString()}');
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<GradeModel> updateGrade(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.patch(
        'grades/$id/',
        data: data,
      );

      if (response.statusCode == 200) {
        return GradeModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la mise à jour de la note');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerFailure('Erreur lors de la mise à jour de la note');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}

