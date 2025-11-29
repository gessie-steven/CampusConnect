import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../models/module_model.dart';

class ModuleRemoteDataSource {
  final Dio dio;

  ModuleRemoteDataSource({required this.dio});

  Future<List<ModuleModel>> getModules({Map<String, dynamic>? queryParams}) async {
    try {
      final response = await dio.get(
        'modules/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ModuleModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ServerFailure('Erreur lors de la récupération des modules');
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

  Future<ModuleModel> getModule(int id) async {
    try {
      final response = await dio.get('modules/$id/');

      if (response.statusCode == 200) {
        return ModuleModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la récupération du module');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ServerFailure('Module non trouvé');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<ModuleModel> createModule(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        'modules/',
        data: data,
      );

      if (response.statusCode == 201) {
        return ModuleModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la création du module');
      }
    } on DioException catch (e) {
      print('❌ Erreur Dio lors de la création du module: ${e.message}');
      if (e.response != null) {
        print('📊 Status code: ${e.response!.statusCode}');
        print('📄 Response data: ${e.response!.data}');
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errors = <String, String>{};
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors[key] = value.first.toString();
              print('⚠️ Erreur champ "$key": ${value.first}');
            } else if (value is String) {
              errors[key] = value;
              print('⚠️ Erreur champ "$key": $value');
            } else if (value is Map) {
              // Gérer les erreurs imbriquées
              value.forEach((k, v) {
                if (v is List && v.isNotEmpty) {
                  errors['$key.$k'] = v.first.toString();
                  print('⚠️ Erreur champ "$key.$k": ${v.first}');
                }
              });
            }
          });
          if (errors.isNotEmpty) {
            final errorMessage = errors.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            throw ValidationFailure(errorMessage);
          }
        }
        final errorMessage = errorData is String ? errorData : errorData.toString();
        throw ServerFailure('Erreur lors de la création du module: $errorMessage');
      } else {
        print('❌ Erreur réseau: ${e.message}');
        throw NetworkFailure('Erreur de réseau: ${e.message}');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      print('❌ Erreur inattendue: ${e.toString()}');
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<ModuleModel> updateModule(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.patch(
        'modules/$id/',
        data: data,
      );

      if (response.statusCode == 200) {
        return ModuleModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerFailure('Erreur lors de la mise à jour du module');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final errors = <String, String>{};
          errorData.forEach((key, value) {
            if (value is List && value.isNotEmpty) {
              errors[key] = value.first as String;
            }
          });
          if (errors.isNotEmpty) {
            throw ValidationFailure(errors.values.first);
          }
        }
        throw ServerFailure('Erreur lors de la mise à jour du module');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }

  Future<void> deleteModule(int id) async {
    try {
      final response = await dio.delete('modules/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw ServerFailure('Erreur lors de la suppression du module');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerFailure('Erreur lors de la suppression du module');
      } else {
        throw NetworkFailure('Erreur de réseau');
      }
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Erreur inattendue: ${e.toString()}');
    }
  }
}

