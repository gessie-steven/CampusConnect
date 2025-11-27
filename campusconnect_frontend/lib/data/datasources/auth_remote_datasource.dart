import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<AuthResponseModel> login(String username, String password) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw AuthFailure('Erreur de connexion');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final detail = errorData['detail'] as String?;
          if (detail != null) {
            throw AuthFailure(detail);
          }
          // Gérer les erreurs de validation
          final errors = errorData['non_field_errors'] as List?;
          if (errors != null && errors.isNotEmpty) {
            throw AuthFailure(errors.first as String);
          }
        }
        throw AuthFailure('Nom d\'utilisateur ou mot de passe incorrect');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Timeout de connexion');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw AuthFailure('Une erreur est survenue: ${e.toString()}');
    }
  }

  Future<AuthResponseModel> signup({
    required String username,
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    required String role,
    String? phone,
    String? studentId,
    String? employeeId,
  }) async {
    try {
      final data = {
        'username': username,
        'email': email,
        'password': password,
        'password2': password2,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        if (phone != null) 'phone': phone,
        if (role == 'student' && studentId != null) 'student_id': studentId,
        if (role == 'teacher' && employeeId != null) 'employee_id': employeeId,
      };

      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/register/',
        data: data,
      );

      if (response.statusCode == 201) {
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw AuthFailure('Erreur lors de l\'inscription');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          // Gérer les erreurs de validation
          final errors = <String, String>{};
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors[key] = value.first as String;
            } else if (value is String) {
              errors[key] = value;
            }
          });

          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            throw ValidationFailure(firstError);
          }

          final detail = errorData['detail'] as String?;
          if (detail != null) {
            throw AuthFailure(detail);
          }
        }
        throw AuthFailure('Erreur lors de l\'inscription');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkFailure('Timeout de connexion');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw AuthFailure('Une erreur est survenue: ${e.toString()}');
    }
  }

  Future<String> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}/auth/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['access'] as String;
      } else {
        throw AuthFailure('Erreur lors du rafraîchissement du token');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw AuthFailure('Token invalide ou expiré');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw AuthFailure('Une erreur est survenue: ${e.toString()}');
    }
  }

  Future<UserModel> getCurrentUser(String accessToken) async {
    try {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
      final response = await dio.get('${AppConstants.baseUrl}/auth/me/');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw AuthFailure('Erreur lors de la récupération du profil');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthFailure('Session expirée');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw AuthFailure('Une erreur est survenue: ${e.toString()}');
    }
  }
}

