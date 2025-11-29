import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/course_resource_model.dart';
import '../../data/repositories/resource_repository.dart';

class ResourceProvider with ChangeNotifier {
  final ResourceRepository resourceRepository;

  ResourceProvider({required this.resourceRepository});

  List<CourseResourceModel> _resources = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CourseResourceModel> get resources => _resources;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadResources({int? moduleId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _resources = await resourceRepository.getResources(moduleId: moduleId);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _resources = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _resources = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _resources = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createResource(FormData formData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await resourceRepository.createResource(formData);
      await loadResources(); // Recharger la liste
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

  Future<bool> createResourceWithUrl(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await resourceRepository.createResourceWithUrl(data);
      await loadResources(); // Recharger la liste
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

  Future<Map<String, dynamic>?> downloadResource(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await resourceRepository.downloadResource(id);
      _errorMessage = null;
      return result;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      return null;
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      return null;
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

