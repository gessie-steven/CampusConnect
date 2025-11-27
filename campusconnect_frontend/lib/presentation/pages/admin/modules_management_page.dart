import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/module_model.dart';
import '../../providers/module_provider.dart';
import '../../widgets/module_form_dialog.dart';

class AdminModulesManagementPage extends StatefulWidget {
  const AdminModulesManagementPage({super.key});

  @override
  State<AdminModulesManagementPage> createState() => _AdminModulesManagementPageState();
}

class _AdminModulesManagementPageState extends State<AdminModulesManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ModuleProvider>(context, listen: false).loadModules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Modules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateModuleDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ModuleProvider>(context, listen: false).loadModules();
            },
          ),
        ],
      ),
      body: Consumer<ModuleProvider>(
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
                    onPressed: () => provider.loadModules(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.modules.isEmpty) {
            return const Center(
              child: Text('Aucun module'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.modules.length,
            itemBuilder: (context, index) {
              final module = provider.modules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.book, color: Colors.blue),
                  title: Text(module.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${module.code}'),
                      Text('Crédits: ${module.credits}'),
                      Text('Étudiants inscrits: ${module.enrolledStudentsCount}'),
                      if (module.teacherName != null)
                        Text('Enseignant: ${module.teacherName}'),
                      Text('Statut: ${module.isActive ? "Actif" : "Inactif"}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditModuleDialog(context, module);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(context, module);
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _showModuleDetails(context, module);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateModuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ModuleFormDialog(),
    );
  }

  void _showEditModuleDialog(BuildContext context, ModuleModel module) {
    showDialog(
      context: context,
      builder: (context) => ModuleFormDialog(module: module),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ModuleModel module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le module ${module.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<ModuleProvider>(context, listen: false);
              final success = await provider.deleteModule(module.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Module supprimé' : provider.errorMessage ?? 'Erreur'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showModuleDetails(BuildContext context, ModuleModel module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(module.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Code: ${module.code}'),
              Text('Crédits: ${module.credits}'),
              if (module.description != null) Text('Description: ${module.description}'),
              if (module.semester != null) Text('Semestre: ${module.semester}'),
              Text('Étudiants inscrits: ${module.enrolledStudentsCount}'),
              if (module.maxStudents != null)
                Text('Capacité maximale: ${module.maxStudents}'),
              if (module.teacherName != null)
                Text('Enseignant: ${module.teacherName}'),
              Text('Statut: ${module.isActive ? "Actif" : "Inactif"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

