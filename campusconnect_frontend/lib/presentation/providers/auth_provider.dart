import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';

class AuthProvider with ChangeNotifier {
  final AuthRemoteDataSource authRemoteDataSource;
  final FlutterSecureStorage secureStorage;
  final Dio dio;

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider({
    required this.authRemoteDataSource,
    required this.secureStorage,
    required this.dio,
  }) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final accessToken = await secureStorage.read(key: AppConstants.accessTokenKey);
      if (accessToken != null) {
        dio.options.headers['Authorization'] = 'Bearer $accessToken';
        await loadUser();
      }
    } catch (e) {
      // Ignore errors when loading stored auth
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await authRemoteDataSource.login(username, password);
      final accessToken = response['access'] as String;
      final refreshToken = response['refresh'] as String?;

      // Store tokens
      await secureStorage.write(key: AppConstants.accessTokenKey, value: accessToken);
      if (refreshToken != null) {
        await secureStorage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
      }

      // Set authorization header
      dio.options.headers['Authorization'] = 'Bearer $accessToken';

      // Load user data
      _user = response['user'] != null
          ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
          : await authRemoteDataSource.getMe();

      _isAuthenticated = true;
      _errorMessage = null;
      return true;
    } on AuthenticationFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      return false;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      return false;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser() async {
    try {
      _user = await authRemoteDataSource.getMe();
      _isAuthenticated = true;
      _errorMessage = null;
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      await logout();
    } finally {
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await secureStorage.delete(key: AppConstants.accessTokenKey);
    await secureStorage.delete(key: AppConstants.refreshTokenKey);
    dio.options.headers.remove('Authorization');
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
