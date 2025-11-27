import '../../core/errors/failures.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await remoteDataSource.login(username, password);
      
      // Save tokens
      if (response['access'] != null) {
        await localDataSource.saveAccessToken(response['access'] as String);
      }
      if (response['refresh'] != null) {
        await localDataSource.saveRefreshToken(response['refresh'] as String);
      }
      
      return response;
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthenticationFailure('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  Future<UserModel> getMe() async {
    try {
      return await remoteDataSource.getMe();
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération du profil: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      await localDataSource.clearTokens();
    } catch (e) {
      // Ignore errors when clearing tokens
    }
  }
}
