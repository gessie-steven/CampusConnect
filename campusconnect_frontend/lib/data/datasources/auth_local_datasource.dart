import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSource({required this.secureStorage});

  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: AppConstants.accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> saveAccessToken(String token) async {
    await secureStorage.write(key: AppConstants.accessTokenKey, value: token);
  }

  Future<void> saveRefreshToken(String token) async {
    await secureStorage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<void> clearTokens() async {
    await secureStorage.delete(key: AppConstants.accessTokenKey);
    await secureStorage.delete(key: AppConstants.refreshTokenKey);
  }
}
