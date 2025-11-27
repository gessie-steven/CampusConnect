import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/grade_model.dart';
import '../../providers/grade_provider.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});

  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GradeProvider>(context, listen: false).loadMyGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GradeProvider>(context, listen: false).loadMyGrades();
            },
          ),
        ],
      ),
      body: Consumer<GradeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadMyGrades(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.grades.isEmpty) {
            return const Center(
              child: Text('Aucune note disponible'),
            );
          }

          // Calculer la moyenne générale
          double totalPoints = 0;
          double totalMaxPoints = 0;
          for (var grade in provider.grades) {
            totalPoints += grade.grade;
            totalMaxPoints += grade.maxGrade;
          }
          final average = totalMaxPoints > 0 ? (totalPoints / totalMaxPoints) * 20 : 0.0;

          return Column(
            children: [
              // Carte de moyenne générale
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Moyenne générale',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            average.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Total notes',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '${provider.grades.length}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Liste des notes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.grades.length,
                  itemBuilder: (context, index) {
                    final grade = provider.grades[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getGradeColor(grade.grade, grade.maxGrade),
                          child: Text(
                            grade.letterGrade ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(grade.moduleName ?? grade.moduleCode ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${grade.gradeTypeDisplay ?? grade.gradeType}'),
                            Text(
                              DateFormat('dd/MM/yyyy', 'fr_FR').format(grade.gradedDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (grade.comment != null && grade.comment!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  grade.comment!,
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${grade.grade.toStringAsFixed(2)}/${grade.maxGrade.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (grade.percentage != null)
                              Text(
                                '${grade.percentage!.toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getGradeColor(double grade, double maxGrade) {
    final percentage = (grade / maxGrade) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}

