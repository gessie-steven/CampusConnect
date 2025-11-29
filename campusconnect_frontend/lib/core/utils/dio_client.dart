import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  static Dio get instance {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor pour ajouter le token d'authentification
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          const storage = FlutterSecureStorage();
          final token = await storage.read(key: AppConstants.accessTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔑 Token ajouté aux headers: ${token.substring(0, 20)}...');
          } else {
            print('⚠️ Aucun token trouvé dans le stockage');
          }
          print('📤 Requête ${options.method} ${options.baseUrl}${options.path}');
          print('📦 Données: ${options.data}');
          print('📋 Headers: ${options.headers}');
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expiré, essayer de le rafraîchir
            const storage = FlutterSecureStorage();
            final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              try {
                final dioRefresh = Dio();
                final response = await dioRefresh.post(
                  '${AppConstants.baseUrl}auth/refresh/',
                  data: {'refresh': refreshToken},
                );
                final newAccessToken = response.data['access'] as String;
                await storage.write(key: AppConstants.accessTokenKey, value: newAccessToken);
                error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                final opts = Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                );
                final cloneReq = await dio.request(
                  error.requestOptions.path,
                  options: opts,
                  data: error.requestOptions.data,
                  queryParameters: error.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              } catch (e) {
                // Refresh failed, clear tokens
                await storage.delete(key: AppConstants.accessTokenKey);
                await storage.delete(key: AppConstants.refreshTokenKey);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}
