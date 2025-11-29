import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/enrollment_model.dart';

class EnrollmentRemoteDataSource {
  final Dio dio;

  EnrollmentRemoteDataSource({required this.dio});

  Future<List<EnrollmentModel>> getMyEnrollments() async {
    try {
      final response = await dio.get('enrollments/my/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => EnrollmentModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des inscriptions');
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

  Future<EnrollmentModel> enrollToModule(int moduleId) async {
    try {
      final response = await dio.post('modules/$moduleId/enroll/');

      if (response.statusCode == 201) {
        return EnrollmentModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de l\'inscription');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] as String?;
          throw ValidationFailure(message ?? 'Erreur lors de l\'inscription');
        }
        throw ServerFailure('Erreur lors de l\'inscription');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<void> unenrollFromModule(int moduleId) async {
    try {
      final response = await dio.post('modules/$moduleId/unenroll/');

      if (response.statusCode != 200) {
        throw ServerFailure('Erreur lors de la désinscription');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] as String?;
          throw ValidationFailure(message ?? 'Erreur lors de la désinscription');
        }
        throw ServerFailure('Erreur lors de la désinscription');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}

