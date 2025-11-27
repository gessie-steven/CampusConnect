import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/constants/routes.dart';
import 'core/utils/dio_client.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/pages/splash_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/signup_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/student_home_page.dart';
import 'presentation/pages/teacher_home_page.dart';
import 'presentation/pages/admin_home_page.dart';

void main() {
  runApp(const CampusConnectApp());
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialiser les dépendances
    final dio = DioClient.instance;
    const secureStorage = FlutterSecureStorage();
    
    final authLocalDataSource = AuthLocalDataSource(secureStorage: secureStorage);
    final authRemoteDataSource = AuthRemoteDataSource(dio: dio);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
    );
    final authProvider = AuthProvider(authRepository: authRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MaterialApp(
        title: 'CampusConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashPage(),
          AppRoutes.login: (context) => const LoginPage(),
          AppRoutes.signup: (context) => const SignupPage(),
          AppRoutes.dashboard: (context) => const DashboardPage(),
          AppRoutes.studentHome: (context) => const StudentHomePage(),
          AppRoutes.teacherHome: (context) => const TeacherHomePage(),
          AppRoutes.adminHome: (context) => const AdminHomePage(),
        },
      ),
    );
  }
}
