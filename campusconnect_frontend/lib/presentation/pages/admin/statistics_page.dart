import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/module_provider.dart';
import '../../providers/enrollment_provider.dart';

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
      final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
      
      userProvider.loadUsers();
      moduleProvider.loadModules();
      enrollmentProvider.loadMyEnrollments(); // Pour obtenir le total des inscriptions
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
              final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
              
              userProvider.loadUsers();
              moduleProvider.loadModules();
              enrollmentProvider.loadMyEnrollments();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          final moduleProvider = Provider.of<ModuleProvider>(context, listen: false);
          final enrollmentProvider = Provider.of<EnrollmentProvider>(context, listen: false);
          
          await Future.wait([
            userProvider.loadUsers(),
            moduleProvider.loadModules(),
            enrollmentProvider.loadMyEnrollments(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Statistiques des utilisateurs
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  if (userProvider.isLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Utilisateurs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Total utilisateurs',
                            userProvider.totalUsers.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildStatCard(
                            'Étudiants',
                            userProvider.totalStudents.toString(),
                            Icons.school,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildStatCard(
                            'Enseignants',
                            userProvider.totalTeachers.toString(),
                            Icons.person,
                            Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _buildStatCard(
                            'Administrateurs',
                            userProvider.totalAdmins.toString(),
                            Icons.admin_panel_settings,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Statistiques des modules
              Consumer<ModuleProvider>(
                builder: (context, moduleProvider, child) {
                  if (moduleProvider.isLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final activeModules = moduleProvider.modules.where((m) => m.isActive).length;
                  final totalEnrollments = moduleProvider.modules.fold<int>(
                    0,
                    (sum, module) => sum + module.enrolledStudentsCount,
                  );

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modules',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Total modules',
                            moduleProvider.modules.length.toString(),
                            Icons.book,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildStatCard(
                            'Modules actifs',
                            activeModules.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                          const SizedBox(height: 8),
                          _buildStatCard(
                            'Total inscriptions',
                            totalEnrollments.toString(),
                            Icons.how_to_reg,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Statistiques des inscriptions
              Consumer<EnrollmentProvider>(
                builder: (context, enrollmentProvider, child) {
                  if (enrollmentProvider.isLoading) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final activeEnrollments = enrollmentProvider.enrollments
                      .where((e) => e.isActive)
                      .length;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inscriptions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Inscriptions actives',
                            activeEnrollments.toString(),
                            Icons.assignment_turned_in,
                            Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

