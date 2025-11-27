import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/user_model.dart';
import 'dart:convert';

class AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSource({required this.secureStorage});

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await secureStorage.write(
        key: AppConstants.accessTokenKey,
        value: accessToken,
      );
      await secureStorage.write(
        key: AppConstants.refreshTokenKey,
        value: refreshToken,
      );
    } catch (e) {
      throw StorageFailure('Erreur lors de la sauvegarde des tokens: ${e.toString()}');
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await secureStorage.read(key: AppConstants.accessTokenKey);
    } catch (e) {
      throw StorageFailure('Erreur lors de la lecture du token: ${e.toString()}');
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await secureStorage.read(key: AppConstants.refreshTokenKey);
    } catch (e) {
      throw StorageFailure('Erreur lors de la lecture du refresh token: ${e.toString()}');
    }
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await secureStorage.write(
        key: AppConstants.userDataKey,
        value: userJson,
      );
    } catch (e) {
      throw StorageFailure('Erreur lors de la sauvegarde de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final userJson = await secureStorage.read(key: AppConstants.userDataKey);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      throw StorageFailure('Erreur lors de la lecture de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<void> clearAll() async {
    try {
      await secureStorage.delete(key: AppConstants.accessTokenKey);
      await secureStorage.delete(key: AppConstants.refreshTokenKey);
      await secureStorage.delete(key: AppConstants.userDataKey);
    } catch (e) {
      throw StorageFailure('Erreur lors de la suppression des données: ${e.toString()}');
    }
  }
}

