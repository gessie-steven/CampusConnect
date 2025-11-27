import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/announcement_model.dart';
import '../../providers/announcement_provider.dart';
import '../../widgets/announcement_form_dialog.dart';

class TeacherAnnouncementsPage extends StatefulWidget {
  const TeacherAnnouncementsPage({super.key});

  @override
  State<TeacherAnnouncementsPage> createState() => _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState extends State<TeacherAnnouncementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementProvider>(context, listen: false).loadAnnouncements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annonces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showCreateAnnouncementDialog(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AnnouncementProvider>(context, listen: false).loadAnnouncements();
            },
          ),
        ],
      ),
      body: Consumer<AnnouncementProvider>(
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
                    onPressed: () => provider.loadAnnouncements(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.announcements.isEmpty) {
            return const Center(
              child: Text('Aucune annonce'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.announcements.length,
            itemBuilder: (context, index) {
              final announcement = provider.announcements[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: announcement.isPinned ? Colors.amber.shade50 : null,
                child: ListTile(
                  leading: announcement.isPinned
                      ? const Icon(Icons.push_pin, color: Colors.amber)
                      : const Icon(Icons.announcement, color: Colors.blue),
                  title: Text(announcement.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(announcement.content),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(announcement.publishedDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (announcement.moduleName != null)
                        Text(
                          'Module: ${announcement.moduleName}',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  trailing: _getPriorityIcon(announcement.priority),
                  onTap: () {
                    _showAnnouncementDetail(context, announcement);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AnnouncementFormDialog(),
    );
  }

  void _showAnnouncementDetail(BuildContext context, AnnouncementModel announcement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(announcement.content),
              const SizedBox(height: 16),
              Text(
                'Publié le: ${DateFormat('dd/MM/yyyy HH:mm', 'fr_FR').format(announcement.publishedDate)}',
                style: const TextStyle(fontSize: 12),
              ),
              if (announcement.moduleName != null)
                Text(
                  'Module: ${announcement.moduleName}',
                  style: const TextStyle(fontSize: 12),
                ),
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

  Widget _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return const Icon(Icons.priority_high, color: Colors.red);
      case 'high':
        return const Icon(Icons.arrow_upward, color: Colors.orange);
      case 'medium':
        return const Icon(Icons.remove, color: Colors.blue);
      default:
        return const Icon(Icons.arrow_downward, color: Colors.grey);
    }
  }
}

