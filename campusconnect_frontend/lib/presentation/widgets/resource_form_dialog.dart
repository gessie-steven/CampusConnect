import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../../../data/models/course_resource_model.dart';
import '../../../data/models/module_model.dart';
import '../providers/resource_provider.dart';
import '../providers/module_provider.dart';

class ResourceFormDialog extends StatefulWidget {
  final CourseResourceModel? resource;

  const ResourceFormDialog({super.key, this.resource});

  @override
  State<ResourceFormDialog> createState() => _ResourceFormDialogState();
}

class _ResourceFormDialogState extends State<ResourceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _externalUrlController = TextEditingController();
  int? _selectedModuleId;
  String? _selectedResourceType;
  bool _isPublic = true;
  PlatformFile? _selectedFile;
  List<ModuleModel> _modules = [];

  final List<String> _resourceTypes = [
    'pdf',
    'docx',
    'pptx',
    'video',
    'link',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.resource != null) {
      _titleController.text = widget.resource!.title;
      _descriptionController.text = widget.resource!.description ?? '';
      _externalUrlController.text = widget.resource!.externalUrl ?? '';
      _selectedModuleId = widget.resource!.moduleId;
      _selectedResourceType = widget.resource!.resourceType;
      _isPublic = widget.resource!.isPublic;
    } else {
      _selectedResourceType = 'other';
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = result.files.single;
          // Déterminer le type de ressource basé sur l'extension
          final extension = _selectedFile!.extension?.toLowerCase();
          if (extension == 'pdf') {
            _selectedResourceType = 'pdf';
          } else if (extension == 'docx' || extension == 'doc') {
            _selectedResourceType = 'docx';
          } else if (extension == 'pptx' || extension == 'ppt') {
            _selectedResourceType = 'pptx';
          } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
            _selectedResourceType = 'video';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.resource == null ? 'Ajouter une ressource' : 'Modifier la ressource'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedResourceType,
                decoration: const InputDecoration(
                  labelText: 'Type de ressource *',
                  border: OutlineInputBorder(),
                ),
                items: _resourceTypes.map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(_getResourceTypeDisplay(type)),
                    )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedResourceType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedResourceType == 'link') ...[
                TextFormField(
                  controller: _externalUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL externe *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'L\'URL est requise pour les liens';
                    }
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme) {
                      return 'URL invalide (doit commencer par http:// ou https://)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_selectedFile != null
                      ? _selectedFile!.name
                      : 'Sélectionner un fichier'),
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Taille: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              SwitchListTile(
                title: const Text('Ressource publique'),
                subtitle: const Text('Accessible à tous les étudiants du module'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
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
              if (_selectedResourceType != 'link' && _selectedFile == null && widget.resource == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez sélectionner un fichier ou fournir une URL'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final provider = Provider.of<ResourceProvider>(context, listen: false);
              
              if (_selectedResourceType == 'link') {
                // Ressource avec URL externe
                final data = {
                  'module': _selectedModuleId,
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  'resource_type': _selectedResourceType,
                  'external_url': _externalUrlController.text.trim(),
                  'is_public': _isPublic,
                };

                final success = await provider.createResourceWithUrl(data);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Ressource ajoutée avec succès'
                            : provider.errorMessage ?? 'Erreur',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              } else if (_selectedFile != null) {
                // Ressource avec fichier
                final formData = FormData.fromMap({
                  'module': _selectedModuleId,
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                  'resource_type': _selectedResourceType,
                  'is_public': _isPublic,
                  'file': await MultipartFile.fromFile(
                    _selectedFile!.path!,
                    filename: _selectedFile!.name,
                  ),
                });

                final success = await provider.createResource(formData);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Ressource ajoutée avec succès'
                            : provider.errorMessage ?? 'Erreur',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  String _getResourceTypeDisplay(String type) {
    switch (type) {
      case 'pdf':
        return 'Document PDF';
      case 'docx':
        return 'Document Word';
      case 'pptx':
        return 'Présentation PowerPoint';
      case 'video':
        return 'Vidéo';
      case 'link':
        return 'Lien Externe';
      default:
        return 'Autre';
    }
  }
}

