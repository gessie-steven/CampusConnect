import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/grade_model.dart';
import '../../providers/grade_provider.dart';
import '../../widgets/grade_form_dialog.dart';

class TeacherGradesPage extends StatefulWidget {
  const TeacherGradesPage({super.key});

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GradeProvider>(context, listen: false).loadGrades();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddGradeDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<GradeProvider>(context, listen: false).loadGrades();
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
                    onPressed: () => provider.loadGrades(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.grades.isEmpty) {
            return const Center(
              child: Text('Aucune note'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                  title: Text(grade.studentName ?? grade.studentUsername ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grade.moduleName ?? grade.moduleCode ?? ''),
                      Text('${grade.gradeTypeDisplay ?? grade.gradeType}'),
                      Text(
                        DateFormat('dd/MM/yyyy', 'fr_FR').format(grade.gradedDate),
                        style: const TextStyle(fontSize: 12),
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
                  onTap: () {
                    _showEditGradeDialog(context, grade);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddGradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const GradeFormDialog(),
    );
  }

  void _showEditGradeDialog(BuildContext context, GradeModel grade) {
    showDialog(
      context: context,
      builder: (context) => GradeFormDialog(grade: grade),
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

