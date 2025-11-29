import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/module_model.dart';
import '../../../data/models/user_model.dart';
import '../providers/module_provider.dart';
import '../providers/user_provider.dart';

class ModuleFormDialog extends StatefulWidget {
  final ModuleModel? module;

  const ModuleFormDialog({super.key, this.module});

  @override
  State<ModuleFormDialog> createState() => _ModuleFormDialogState();
}

class _ModuleFormDialogState extends State<ModuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _creditsController = TextEditingController();
  final _semesterController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  int? _selectedTeacherId;
  bool _isActive = true;
  List<UserModel> _teachers = [];

  @override
  void initState() {
    super.initState();
    if (widget.module != null) {
      _codeController.text = widget.module!.code;
      _nameController.text = widget.module!.name;
      _descriptionController.text = widget.module!.description ?? '';
      _creditsController.text = widget.module!.credits.toString();
      _semesterController.text = widget.module!.semester ?? '';
      _maxStudentsController.text = widget.module!.maxStudents?.toString() ?? '';
      _selectedTeacherId = widget.module!.teacherId;
      _isActive = widget.module!.isActive;
    }
    // Charger les données après le build pour éviter setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeachers();
    });
  }

  Future<void> _loadTeachers() async {
    if (!mounted) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUsers(role: 'teacher');
    
    if (!mounted) return;
    
    setState(() {
      _teachers = userProvider.getUsersByRole('teacher');
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    _semesterController.dispose();
    _maxStudentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.module == null ? 'Créer un module' : 'Modifier le module'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code du module *',
                  border: OutlineInputBorder(),
                ),
                enabled: widget.module == null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le code est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du module *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(
                  labelText: 'Crédits ECTS *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Les crédits sont requis';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Valeur numérique requise';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _semesterController,
                decoration: const InputDecoration(
                  labelText: 'Semestre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxStudentsController,
                decoration: const InputDecoration(
                  labelText: 'Capacité maximale',
                  border: OutlineInputBorder(),
                  hintText: 'Laisser vide pour illimité',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null) {
                      return 'Valeur numérique requise';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Enseignant référent',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Aucun'),
                  ),
                  ..._teachers.map((teacher) => DropdownMenuItem<int>(
                        value: teacher.id,
                        child: Text(teacher.fullName),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTeacherId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Module actif'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
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
              final provider = Provider.of<ModuleProvider>(context, listen: false);
              final data = {
                'code': _codeController.text.trim().toUpperCase(),
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                'credits': int.parse(_creditsController.text.trim()),
                'semester': _semesterController.text.trim().isEmpty
                    ? null
                    : _semesterController.text.trim(),
                'max_students': _maxStudentsController.text.trim().isEmpty
                    ? null
                    : int.tryParse(_maxStudentsController.text.trim()),
                'teacher': _selectedTeacherId,
                'is_active': _isActive,
              };

              bool success;
              if (widget.module == null) {
                success = await provider.createModule(data);
              } else {
                success = await provider.updateModule(widget.module!.id, data);
              }

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? widget.module == null
                              ? 'Module créé avec succès'
                              : 'Module modifié avec succès'
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
}

