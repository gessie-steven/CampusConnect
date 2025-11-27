import 'package:flutter/foundation.dart';
import '../../core/errors/failures.dart';
import '../../data/models/announcement_model.dart';
import '../../data/repositories/announcement_repository.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementRepository announcementRepository;

  AnnouncementProvider({required this.announcementRepository});

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyAnnouncements({int? moduleId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await announcementRepository.getMyAnnouncements(moduleId: moduleId);
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _announcements = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _announcements = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAnnouncements({int? moduleId, String? priority}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await announcementRepository.getAnnouncements(
        moduleId: moduleId,
        priority: priority,
      );
      _errorMessage = null;
    } on ServerFailure catch (e) {
      _errorMessage = e.message;
      _announcements = [];
    } on NetworkFailure catch (e) {
      _errorMessage = e.message;
      _announcements = [];
    } catch (e) {
      _errorMessage = 'Erreur inattendue: ${e.toString()}';
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await announcementRepository.createAnnouncement(data);
      await loadAnnouncements(); // Recharger la liste
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

