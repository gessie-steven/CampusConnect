import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await dio.post(
        '${AppConstants.baseUrl}auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw AuthenticationFailure('Erreur lors de la connexion');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthenticationFailure('Identifiants incorrects');
      } else if (e.response != null) {
        throw ServerFailure('Erreur serveur: ${e.response?.statusCode}');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthenticationFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await dio.get('${AppConstants.baseUrl}auth/me/');

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la récupération du profil');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthenticationFailure('Non authentifié');
      } else if (e.response != null) {
        throw ServerFailure('Erreur serveur: ${e.response?.statusCode}');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}
