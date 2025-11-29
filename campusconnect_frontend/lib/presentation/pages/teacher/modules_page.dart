import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/module_model.dart';
import '../../providers/module_provider.dart';
import '../../widgets/module_form_dialog.dart';

class TeacherModulesPage extends StatefulWidget {
  const TeacherModulesPage({super.key});

  @override
  State<TeacherModulesPage> createState() => _TeacherModulesPageState();
}

class _TeacherModulesPageState extends State<TeacherModulesPage> {
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
        title: const Text('Mes Modules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const ModuleFormDialog(),
              );
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
                      Text(
                        'Étudiants inscrits: ${module.enrolledStudentsCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (module.maxStudents != null)
                        Text('Capacité max: ${module.maxStudents}'),
                    ],
                  ),
                  trailing: module.isActive
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.cancel, color: Colors.red),
                  onTap: () {
                    // TODO: Navigate to module detail page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleDetailPage(module: module),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ModuleDetailPage extends StatelessWidget {
  final ModuleModel module;

  const ModuleDetailPage({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(module.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Code: ${module.code}'),
                    Text('Crédits: ${module.credits}'),
                    if (module.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(module.description!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Étudiants inscrits: ${module.enrolledStudentsCount}'),
                    if (module.maxStudents != null)
                      Text('Capacité maximale: ${module.maxStudents}'),
                    Text('Statut: ${module.isActive ? "Actif" : "Inactif"}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

