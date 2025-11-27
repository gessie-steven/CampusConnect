import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/module_model.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/module_provider.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  bool _showAvailableModules = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EnrollmentProvider>(context, listen: false).loadMyEnrollments();
      Provider.of<ModuleProvider>(context, listen: false).loadModules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes Cours'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mes inscriptions'),
              Tab(text: 'Cours disponibles'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyEnrollments(),
            _buildAvailableModules(),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEnrollments() {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<EnrollmentProvider>(context, listen: false).loadMyEnrollments();
      },
      child: Consumer<EnrollmentProvider>(
        builder: (context, enrollmentProvider, child) {
          if (enrollmentProvider.isLoading && enrollmentProvider.enrollments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (enrollmentProvider.errorMessage != null && enrollmentProvider.enrollments.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        enrollmentProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => enrollmentProvider.loadMyEnrollments(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (enrollmentProvider.enrollments.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 500,
                child: Center(
                  child: Text('Aucune inscription'),
                ),
              ),
            );
          }

          return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: enrollmentProvider.enrollments.length,
          itemBuilder: (context, index) {
            final enrollment = enrollmentProvider.enrollments[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.book, color: Colors.blue),
                title: Text(enrollment.moduleName ?? enrollment.moduleCode ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${enrollment.moduleCode ?? ''}'),
                    if (enrollment.grade != null)
                      Text(
                        'Note: ${enrollment.grade!.toStringAsFixed(2)}/20',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                trailing: enrollment.isActive
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableModules() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          Provider.of<ModuleProvider>(context, listen: false).loadModules(),
          Provider.of<EnrollmentProvider>(context, listen: false).loadMyEnrollments(),
        ]);
      },
      child: Consumer2<ModuleProvider, EnrollmentProvider>(
        builder: (context, moduleProvider, enrollmentProvider, child) {
          if (moduleProvider.isLoading && moduleProvider.modules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (moduleProvider.errorMessage != null && moduleProvider.modules.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        moduleProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => moduleProvider.loadModules(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

        // Filtrer les modules où l'étudiant n'est pas déjà inscrit
        final enrolledModuleIds = enrollmentProvider.enrollments
            .where((e) => e.isActive)
            .map((e) => e.moduleId)
            .toSet();

        final availableModules = moduleProvider.modules
            .where((m) => m.isActive && !enrolledModuleIds.contains(m.id))
            .toList();

        if (availableModules.isEmpty) {
          return const Center(
            child: Text('Aucun cours disponible'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: availableModules.length,
          itemBuilder: (context, index) {
            final module = availableModules[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: Text(module.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${module.code}'),
                    Text('Crédits: ${module.credits}'),
                    if (module.teacherName != null)
                      Text('Enseignant: ${module.teacherName}'),
                    if (module.maxStudents != null)
                      Text(
                        'Places: ${module.enrolledStudentsCount}/${module.maxStudents}',
                      ),
                  ],
                ),
                trailing: module.isFull
                    ? const Text('Complet', style: TextStyle(color: Colors.red))
                    : ElevatedButton(
                        onPressed: () async {
                          final success = await enrollmentProvider.enrollToModule(module.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Inscription réussie'
                                    : enrollmentProvider.errorMessage ?? 'Erreur'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                            if (success) {
                              enrollmentProvider.loadMyEnrollments();
                            }
                          }
                        },
                        child: const Text('S\'inscrire'),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

