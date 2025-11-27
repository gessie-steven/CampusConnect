import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository authRepository;

  AuthProvider({required this.authRepository});

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        _user = user;
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
        _user = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _user = null;
      _errorMessage = 'Erreur lors de la vérification de la session';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.login(username, password);
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ValidationFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue';
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authRepository.signup(
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
      _user = user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on ValidationFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue';
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authRepository.logout();
      _user = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur lors de la déconnexion';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

