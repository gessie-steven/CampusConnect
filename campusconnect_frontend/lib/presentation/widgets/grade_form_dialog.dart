import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/grade_model.dart';
import '../../../data/models/module_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/grade_provider.dart';
import '../providers/module_provider.dart';
import '../providers/user_provider.dart';

class GradeFormDialog extends StatefulWidget {
  final GradeModel? grade;

  const GradeFormDialog({super.key, this.grade});

  @override
  State<GradeFormDialog> createState() => _GradeFormDialogState();
}

class _GradeFormDialogState extends State<GradeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedStudentId;
  int? _selectedModuleId;
  String? _selectedGradeType;
  final _gradeController = TextEditingController();
  final _maxGradeController = TextEditingController();
  final _commentController = TextEditingController();
  List<UserModel> _students = [];
  List<ModuleModel> _modules = [];

  final List<String> _gradeTypes = [
    'exam',
    'quiz',
    'assignment',
    'project',
    'participation',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.grade != null) {
      _selectedStudentId = widget.grade!.studentId;
      _selectedModuleId = widget.grade!.moduleId;
      _selectedGradeType = widget.grade!.gradeType;
      _gradeController.text = widget.grade!.grade.toString();
      _maxGradeController.text = widget.grade!.maxGrade.toString();
      _commentController.text = widget.grade!.comment ?? '';
    } else {
      _maxGradeController.text = '20';
    }
    // Charger les données après le build pour éviter setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);

    await userProvider.loadUsers(role: 'student');
    await moduleProvider.loadModules();

    if (!mounted) return;
    
    setState(() {
      _students = userProvider.getUsersByRole('student');
      _modules = moduleProvider.modules;
    });
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _maxGradeController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.grade == null ? 'Ajouter une note' : 'Modifier la note'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedStudentId,
                decoration: const InputDecoration(
                  labelText: 'Étudiant *',
                  border: OutlineInputBorder(),
                ),
                items: _students.map((student) => DropdownMenuItem<int>(
                      value: student.id,
                      child: Text(student.fullName),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStudentId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'L\'étudiant est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedModuleId,
                decoration: const InputDecoration(
                  labelText: 'Module *',
                  border: OutlineInputBorder(),
                ),
                items: _modules.map((module) => DropdownMenuItem<int>(
                      value: module.id,
                      child: Text('${module.code} - ${module.name}'),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModuleId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Le module est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGradeType,
                decoration: const InputDecoration(
                  labelText: 'Type de note *',
                  border: OutlineInputBorder(),
                ),
                items: _gradeTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(_getGradeTypeDisplay(type)),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGradeType = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Le type est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _gradeController,
                      decoration: const InputDecoration(
                        labelText: 'Note obtenue *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La note est requise';
                        }
                        final grade = double.tryParse(value);
                        if (grade == null) {
                          return 'Valeur numérique requise';
                        }
                        if (grade < 0) {
                          return 'La note ne peut pas être négative';
                        }
                        final maxGrade = double.tryParse(_maxGradeController.text) ?? 20;
                        if (grade > maxGrade) {
                          return 'La note ne peut pas être supérieure à $maxGrade';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxGradeController,
                      decoration: const InputDecoration(
                        labelText: 'Note maximale *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La note maximale est requise';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Valeur numérique requise';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final provider = Provider.of<GradeProvider>(context, listen: false);
              // Vérifier que tous les champs requis sont remplis
              if (_selectedStudentId == null || _selectedModuleId == null || _selectedGradeType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs requis'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final data = {
                'student': _selectedStudentId,
                'module': _selectedModuleId,
                'grade_type': _selectedGradeType,
                'grade': double.parse(_gradeController.text),
                'max_grade': double.parse(_maxGradeController.text),
                'comment': _commentController.text.trim().isEmpty
                    ? null
                    : _commentController.text.trim(),
              };

              bool success;
              if (widget.grade == null) {
                success = await provider.createGrade(data);
              } else {
                success = await provider.updateGrade(widget.grade!.id, data);
              }

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? widget.grade == null
                              ? 'Note ajoutée avec succès'
                              : 'Note modifiée avec succès'
                          : provider.errorMessage ?? 'Erreur lors de la sauvegarde',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: Duration(seconds: success ? 2 : 5),
                  ),
                );
              }
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  String _getGradeTypeDisplay(String type) {
    switch (type) {
      case 'exam':
        return 'Examen';
      case 'quiz':
        return 'Quiz';
      case 'assignment':
        return 'Devoir';
      case 'project':
        return 'Projet';
      case 'participation':
        return 'Participation';
      default:
        return 'Autre';
    }
  }
}

