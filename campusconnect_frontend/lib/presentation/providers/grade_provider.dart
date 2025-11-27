import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/grade_model.dart';
import '../../data/repositories/grade_repository.dart';

class GradeProvider with ChangeNotifier {
  final GradeRepository gradeRepository;

  GradeProvider({required this.gradeRepository});

  List<GradeModel> _grades = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<GradeModel> get grades => _grades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyGrades({int? moduleId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _grades = await gradeRepository.getMyGrades(moduleId: moduleId);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _grades = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _grades = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _grades = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGrades({int? moduleId, int? studentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _grades = await gradeRepository.getGrades(moduleId: moduleId, studentId: studentId);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _grades = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _grades = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _grades = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGrade(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await gradeRepository.createGrade(data);
      await loadGrades(); // Recharger la liste
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

  Future<bool> updateGrade(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await gradeRepository.updateGrade(id, data);
      await loadGrades(); // Recharger la liste
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

