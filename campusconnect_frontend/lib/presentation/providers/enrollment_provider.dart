import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/enrollment_model.dart';
import '../../data/repositories/enrollment_repository.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentRepository enrollmentRepository;

  EnrollmentProvider({required this.enrollmentRepository});

  List<EnrollmentModel> _enrollments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EnrollmentModel> get enrollments => _enrollments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyEnrollments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _enrollments = await enrollmentRepository.getMyEnrollments();
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _enrollments = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _enrollments = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _enrollments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enrollToModule(int moduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await enrollmentRepository.enrollToModule(moduleId);
      await loadMyEnrollments(); // Recharger la liste
      _errorMessage = null;
      return true;
    } on ValidationFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      return false;
    } on NetworkFailure catch (e) {
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

  Future<bool> unenrollFromModule(int moduleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await enrollmentRepository.unenrollFromModule(moduleId);
      await loadMyEnrollments(); // Recharger la liste
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

