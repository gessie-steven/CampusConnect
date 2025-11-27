import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                user.fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              user.roleDisplay,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            // Informations
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),
                  if (user.phone != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text('Téléphone'),
                      subtitle: Text(user.phone!),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Nom d\'utilisateur'),
                    subtitle: Text(user.username),
                  ),
                  if (user.dateJoined != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date d\'inscription'),
                      subtitle: Text(
                        '${user.dateJoined!.day}/${user.dateJoined!.month}/${user.dateJoined!.year}',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

