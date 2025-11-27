import 'package:flutter_test/flutter_test.dart';
import 'package:campusconnect_frontend/core/errors/failures.dart';
import 'package:campusconnect_frontend/data/models/grade_model.dart';
import 'package:campusconnect_frontend/data/repositories/grade_repository.dart';
import 'package:campusconnect_frontend/presentation/providers/grade_provider.dart';

class MockGradeRepository extends GradeRepository {
  MockGradeRepository() : super(remoteDataSource: throw UnimplementedError());

  List<GradeModel>? mockGrades;
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<List<GradeModel>> getMyGrades({int? moduleId}) async {
    if (shouldThrowError) {
      throw ServerFailure(errorMessage ?? 'Erreur de test');
    }
    return mockGrades ?? [];
  }
}

void main() {
  group('GradeProvider', () {
    test('initial state is correct', () {
      final repository = MockGradeRepository();
      final provider = GradeProvider(gradeRepository: repository);

      expect(provider.grades, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('loadMyGrades sets loading state correctly', () async {
      final repository = MockGradeRepository();
      repository.mockGrades = [];
      final provider = GradeProvider(gradeRepository: repository);

      final future = provider.loadMyGrades();
      expect(provider.isLoading, true);

      await future;
      expect(provider.isLoading, false);
    });

    test('loadMyGrades handles errors correctly', () async {
      final repository = MockGradeRepository();
      repository.shouldThrowError = true;
      repository.errorMessage = 'Erreur de test';
      final provider = GradeProvider(gradeRepository: repository);

      await provider.loadMyGrades();

      expect(provider.errorMessage, 'Erreur de test');
      expect(provider.grades, isEmpty);
    });
  });
}

