import '../../core/errors/failures.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepository({required this.remoteDataSource});

  Future<List<UserModel>> getUsers({String? role}) async {
    try {
      return await remoteDataSource.getUsers(role: role);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération des utilisateurs: ${e.toString()}');
    }
  }

  Future<UserModel> getUser(int id) async {
    try {
      return await remoteDataSource.getUser(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la récupération de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<UserModel> createUser(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createUser(data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la création de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.updateUser(id, data);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await remoteDataSource.deleteUser(id);
    } on Failure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Erreur lors de la suppression de l\'utilisateur: ${e.toString()}');
    }
  }
}

