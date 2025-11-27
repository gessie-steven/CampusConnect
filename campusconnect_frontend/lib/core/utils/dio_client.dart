import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DioClient {
  static Dio? _dio;
  static const _storage = FlutterSecureStorage();

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
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

      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Ajouter le token d'accès si disponible
            final token = await _storage.read(key: AppConstants.accessTokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (error, handler) async {
            // Si erreur 401, essayer de rafraîchir le token
            if (error.response?.statusCode == 401) {
              try {
                final refreshToken = await _storage.read(
                  key: AppConstants.refreshTokenKey,
                );
                if (refreshToken != null) {
                  final dio = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
                  final response = await dio.post(
                    '${AppConstants.baseUrl}/auth/refresh/',
                    data: {'refresh': refreshToken},
                  );

                  if (response.statusCode == 200) {
                    final newAccessToken = response.data['access'] as String;
                    await _storage.write(
                      key: AppConstants.accessTokenKey,
                      value: newAccessToken,
                    );

                    // Réessayer la requête originale avec le nouveau token
                    error.requestOptions.headers['Authorization'] =
                        'Bearer $newAccessToken';
                    final opts = Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    );
                    final cloneReq = await _dio!.request(
                      error.requestOptions.path,
                      options: opts,
                      data: error.requestOptions.data,
                      queryParameters: error.requestOptions.queryParameters,
                    );
                    return handler.resolve(cloneReq);
                  }
                }
              } catch (e) {
                // Si le refresh échoue, supprimer les tokens
                await _storage.delete(key: AppConstants.accessTokenKey);
                await _storage.delete(key: AppConstants.refreshTokenKey);
              }
            }
            return handler.next(error);
          },
        ),
      );
    }
    return _dio!;
  }
}

