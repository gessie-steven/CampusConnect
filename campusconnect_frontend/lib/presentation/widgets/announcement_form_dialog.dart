import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/models/module_model.dart';
import '../providers/announcement_provider.dart';
import '../providers/module_provider.dart';

class AnnouncementFormDialog extends StatefulWidget {
  final AnnouncementModel? announcement;

  const AnnouncementFormDialog({super.key, this.announcement});

  @override
  State<AnnouncementFormDialog> createState() => _AnnouncementFormDialogState();
}

class _AnnouncementFormDialogState extends State<AnnouncementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int? _selectedModuleId;
  String? _selectedPriority;
  String? _selectedTargetRole;
  DateTime? _expiryDate;
  bool _isPinned = false;
  List<ModuleModel> _modules = [];

  final List<String> _priorities = ['low', 'normal', 'high', 'urgent'];
  final List<String> _targetRoles = ['student', 'teacher', 'admin'];

  @override
  void initState() {
    super.initState();
    if (widget.announcement != null) {
      _titleController.text = widget.announcement!.title;
      _contentController.text = widget.announcement!.content;
      _selectedModuleId = widget.announcement!.moduleId;
      _selectedPriority = widget.announcement!.priority;
      _selectedTargetRole = widget.announcement!.targetAudience;
      _expiryDate = widget.announcement!.expiryDate;
      _isPinned = widget.announcement!.isPinned;
    } else {
      _selectedPriority = 'normal';
    }
    // Charger les données après le build pour éviter setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModules();
    });
  }

  Future<void> _loadModules() async {
    if (!mounted) return;
    
    final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
    await moduleProvider.loadModules();
    
    if (!mounted) return;
    
    setState(() {
      _modules = moduleProvider.modules;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.announcement == null ? 'Créer une annonce' : 'Modifier l\'annonce'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Contenu *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le contenu est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedModuleId,
                decoration: const InputDecoration(
                  labelText: 'Module (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Annonce générale si vide',
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('Annonce générale'),
                  ),
                  ..._modules.map((module) => DropdownMenuItem<int>(
                        value: module.id,
                        child: Text('${module.code} - ${module.name}'),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedModuleId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priorité *',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.map((priority) => DropdownMenuItem<String>(
                      value: priority,
                      child: Text(_getPriorityDisplay(priority)),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTargetRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle ciblé (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Tous si vide',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tous'),
                  ),
                  ..._targetRoles.map((role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(_getRoleDisplay(role)),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTargetRole = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date d\'expiration'),
                subtitle: Text(
                  _expiryDate != null
                      ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_expiryDate!)
                      : 'Aucune expiration',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expiryDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _expiryDate = null;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _expiryDate = date;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Épingler l\'annonce'),
                value: _isPinned,
                onChanged: (value) {
                  setState(() {
                    _isPinned = value;
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
              final provider = Provider.of<AnnouncementProvider>(context, listen: false);
              final data = {
                'title': _titleController.text.trim(),
                'content': _contentController.text.trim(),
                'module': _selectedModuleId,
                'priority': _selectedPriority,
                'target_audience': _selectedTargetRole,
                'expiry_date': _expiryDate?.toIso8601String(),
                'is_pinned': _isPinned,
              };

              bool success;
              if (widget.announcement == null) {
                success = await provider.createAnnouncement(data);
              } else {
                // TODO: Implémenter updateAnnouncement dans AnnouncementProvider
                success = false;
              }

              if (context.mounted) {
                if (success) {
                  Navigator.pop(context);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? widget.announcement == null
                              ? 'Annonce créée avec succès'
                              : 'Annonce modifiée avec succès'
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

  String _getPriorityDisplay(String priority) {
    switch (priority) {
      case 'low':
        return 'Basse';
      case 'normal':
        return 'Normale';
      case 'high':
        return 'Haute';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'student':
        return 'Étudiant';
      case 'teacher':
        return 'Enseignant';
      case 'admin':
        return 'Administrateur';
      default:
        return role;
    }
  }
}

