import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/course_session_model.dart';
import '../../data/repositories/session_repository.dart';

class SessionProvider with ChangeNotifier {
  final SessionRepository sessionRepository;

  SessionProvider({required this.sessionRepository});

  List<CourseSessionModel> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CourseSessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMySchedule({String? dateFrom, String? dateTo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await sessionRepository.getMySchedule(
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _sessions = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _sessions = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _sessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSessions({int? moduleId, String? dateFrom, String? dateTo}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sessions = await sessionRepository.getSessions(
        moduleId: moduleId,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _sessions = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _sessions = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _sessions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSession(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await sessionRepository.createSession(data);
      await loadSessions(); // Recharger la liste
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

