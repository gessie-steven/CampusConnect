import '../../core/errors/failures.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<UserModel> login(String username, String password) async {
    try {
      final authResponse = await remoteDataSource.login(username, password);
      
      if (authResponse.accessToken != null && authResponse.refreshToken != null) {
        await localDataSource.saveTokens(
          authResponse.accessToken!,
          authResponse.refreshToken!,
        );
      }

      if (authResponse.user != null) {
        await localDataSource.saveUser(authResponse.user!);
        return authResponse.user!;
      } else {
        // Si l'utilisateur n'est pas dans la réponse, le récupérer
        final user = await remoteDataSource.getCurrentUser(authResponse.accessToken!);
        await localDataSource.saveUser(user);
        return user;
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  Future<UserModel> signup({
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
      final authResponse = await remoteDataSource.signup(
        username: username,
        email: email,
        password: password,
        password2: password2,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phone: phone,
        studentId: studentId,
        employeeId: employeeId,
      );

      if (authResponse.accessToken != null && authResponse.refreshToken != null) {
        await localDataSource.saveTokens(
          authResponse.accessToken!,
          authResponse.refreshToken!,
        );
      }

      if (authResponse.user != null) {
        await localDataSource.saveUser(authResponse.user!);
        return authResponse.user!;
      } else {
        throw AuthFailure('Erreur lors de l\'inscription');
      }
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      if (refreshToken == null) {
        throw AuthFailure('Aucun refresh token disponible');
      }

      final newAccessToken = await remoteDataSource.refreshToken(refreshToken);
      final currentRefreshToken = await localDataSource.getRefreshToken();
      
      if (currentRefreshToken != null) {
        await localDataSource.saveTokens(newAccessToken, currentRefreshToken);
      }

      return newAccessToken;
    } on Failure {
      rethrow;
    } catch (e) {
      throw AuthFailure('Erreur lors du rafraîchissement du token: ${e.toString()}');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // D'abord essayer de récupérer depuis le stockage local
      final localUser = await localDataSource.getUser();
      if (localUser != null) {
        return localUser;
      }

      // Sinon, récupérer depuis l'API
      final accessToken = await localDataSource.getAccessToken();
      if (accessToken == null) {
        return null;
      }

      final user = await remoteDataSource.getCurrentUser(accessToken);
      await localDataSource.saveUser(user);
      return user;
    } on Failure {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      return accessToken != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await localDataSource.clearAll();
    } catch (e) {
      throw StorageFailure('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await localDataSource.getAccessToken();
    } catch (e) {
      return null;
    }
  }
}

