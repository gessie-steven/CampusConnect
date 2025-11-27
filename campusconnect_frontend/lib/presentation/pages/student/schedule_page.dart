import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/models/course_session_model.dart';
import '../../providers/session_provider.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).loadMySchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emploi du temps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<SessionProvider>(context, listen: false).loadMySchedule();
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
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
                    onPressed: () => provider.loadMySchedule(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.sessions.isEmpty) {
            return const Center(
              child: Text('Aucune session prévue'),
            );
          }

          // Grouper les sessions par date
          final groupedSessions = <DateTime, List<CourseSessionModel>>{};
          for (var session in provider.sessions) {
            final date = DateTime(session.date.year, session.date.month, session.date.day);
            groupedSessions.putIfAbsent(date, () => []).add(session);
          }

          final sortedDates = groupedSessions.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final sessions = groupedSessions[date]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, top: index > 0 ? 16 : 0),
                    child: Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...sessions.map((session) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getSessionTypeColor(session.sessionType),
                        child: Icon(
                          _getSessionTypeIcon(session.sessionType),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(session.moduleCode ?? session.moduleName ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.moduleName ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            '${session.startTime.substring(0, 5)} - ${session.endTime.substring(0, 5)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (session.location != null)
                            Text('📍 ${session.location}'),
                        ],
                      ),
                      trailing: session.isOnline
                          ? const Icon(Icons.videocam, color: Colors.blue)
                          : null,
                    ),
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Color _getSessionTypeColor(String type) {
    switch (type) {
      case 'exam':
        return Colors.red;
      case 'lecture':
        return Colors.blue;
      case 'tutorial':
        return Colors.green;
      case 'lab':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSessionTypeIcon(String type) {
    switch (type) {
      case 'exam':
        return Icons.assignment;
      case 'lecture':
        return Icons.school;
      case 'tutorial':
        return Icons.groups;
      case 'lab':
        return Icons.science;
      default:
        return Icons.event;
    }
  }
}

