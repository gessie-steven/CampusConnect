import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository userRepository;

  UserProvider({required this.userRepository});

  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Statistiques
  int _totalUsers = 0;
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalAdmins = 0;

  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalUsers => _totalUsers;
  int get totalStudents => _totalStudents;
  int get totalTeachers => _totalTeachers;
  int get totalAdmins => _totalAdmins;

  Future<void> loadUsers({String? role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await userRepository.getUsers(role: role);
      _updateStatistics();
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _users = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _users = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await userRepository.getUser(id);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _selectedUser = null;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _selectedUser = null;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _selectedUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await userRepository.createUser(data);
      await loadUsers(); // Recharger la liste
      _errorMessage = null;
      return true;
    } on ValidationFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await userRepository.updateUser(id, data);
      await loadUsers(); // Recharger la liste
      _errorMessage = null;
      return true;
    } on ValidationFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await userRepository.deleteUser(id);
      await loadUsers(); // Recharger la liste
      _errorMessage = null;
      return true;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateStatistics() {
    _totalUsers = _users.length;
    _totalStudents = _users.where((u) => u.isStudent).length;
    _totalTeachers = _users.where((u) => u.isTeacher).length;
    _totalAdmins = _users.where((u) => u.isAdmin).length;
  }

  List<UserModel> getUsersByRole(String role) {
    return _users.where((u) => u.role == role).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

