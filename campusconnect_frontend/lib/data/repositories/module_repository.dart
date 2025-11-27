import '../../core/errors/failures.dart';
import '../datasources/module_remote_datasource.dart';
import '../models/module_model.dart';

class ModuleRepository {
  final ModuleRemoteDataSource remoteDataSource;

  ModuleRepository({required this.remoteDataSource});

  Future<List<ModuleModel>> getModules({Map<String, dynamic>? queryParams}) async {
    try {
      return await remoteDataSource.getModules(queryParams: queryParams);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des modules: ${e.toString()}');
    }
  }

  Future<ModuleModel> getModule(int id) async {
    try {
      return await remoteDataSource.getModule(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération du module: ${e.toString()}');
    }
  }

  Future<ModuleModel> createModule(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createModule(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création du module: ${e.toString()}');
    }
  }

  Future<ModuleModel> updateModule(int id, Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.updateModule(id, data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la mise à jour du module: ${e.toString()}');
    }
  }

  Future<void> deleteModule(int id) async {
    try {
      await remoteDataSource.deleteModule(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la suppression du module: ${e.toString()}');
    }
  }
}

