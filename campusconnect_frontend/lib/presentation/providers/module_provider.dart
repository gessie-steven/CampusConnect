import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/module_model.dart';
import '../../data/repositories/module_repository.dart';

class ModuleProvider with ChangeNotifier {
  final ModuleRepository moduleRepository;

  ModuleProvider({required this.moduleRepository});

  List<ModuleModel> _modules = [];
  ModuleModel? _selectedModule;
  bool _isLoading = false;
  String? _errorMessage;

  List<ModuleModel> get modules => _modules;
  ModuleModel? get selectedModule => _selectedModule;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadModules({Map<String, dynamic>? queryParams}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _modules = await moduleRepository.getModules(queryParams: queryParams);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _modules = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _modules = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _modules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadModule(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedModule = await moduleRepository.getModule(id);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _selectedModule = null;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _selectedModule = null;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _selectedModule = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createModule(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await moduleRepository.createModule(data);
      await loadModules(); // Recharger la liste
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

  Future<bool> updateModule(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await moduleRepository.updateModule(id, data);
      await loadModules(); // Recharger la liste
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

  Future<bool> deleteModule(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await moduleRepository.deleteModule(id);
      await loadModules(); // Recharger la liste
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

