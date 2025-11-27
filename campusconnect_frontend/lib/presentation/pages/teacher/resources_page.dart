import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/course_resource_model.dart';
import '../../providers/resource_provider.dart';
import '../../widgets/resource_form_dialog.dart';

class TeacherResourcesPage extends StatefulWidget {
  const TeacherResourcesPage({super.key});

  @override
  State<TeacherResourcesPage> createState() => _TeacherResourcesPageState();
}

class _TeacherResourcesPageState extends State<TeacherResourcesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ResourceProvider>(context, listen: false).loadResources();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ressources de Cours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showUploadResourceDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ResourceProvider>(context, listen: false).loadResources();
            },
          ),
        ],
      ),
      body: Consumer<ResourceProvider>(
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
                    onPressed: () => provider.loadResources(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.resources.isEmpty) {
            return const Center(
              child: Text('Aucune ressource'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.resources.length,
            itemBuilder: (context, index) {
              final resource = provider.resources[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getResourceIcon(resource.resourceType),
                    color: Colors.blue,
                  ),
                  title: Text(resource.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.moduleName ?? resource.moduleCode ?? ''),
                      Text('Type: ${resource.resourceTypeDisplay ?? resource.resourceType}'),
                      if (resource.fileSizeHuman != null)
                        Text('Taille: ${resource.fileSizeHuman}'),
                      Text('Téléchargements: ${resource.downloadCount}'),
                    ],
                  ),
                  trailing: resource.isPublic
                      ? const Icon(Icons.public, color: Colors.green)
                      : const Icon(Icons.lock, color: Colors.orange),
                  onTap: () {
                    if (resource.fileUrl != null || resource.externalUrl != null) {
                      // TODO: Open resource
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture de la ressource...')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showUploadResourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ResourceFormDialog(),
    );
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
        return Icons.description;
      case 'pptx':
        return Icons.slideshow;
      case 'video':
        return Icons.video_library;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }
}

