import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'core/constants/routes.dart';
import 'core/utils/dio_client.dart';
import 'data/datasources/auth_local_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/module_remote_datasource.dart';
import 'data/datasources/enrollment_remote_datasource.dart';
import 'data/datasources/grade_remote_datasource.dart';
import 'data/datasources/session_remote_datasource.dart';
import 'data/datasources/resource_remote_datasource.dart';
import 'data/datasources/announcement_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/module_repository.dart';
import 'data/repositories/enrollment_repository.dart';
import 'data/repositories/grade_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/resource_repository.dart';
import 'data/repositories/announcement_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/module_provider.dart';
import 'presentation/providers/enrollment_provider.dart';
import 'presentation/providers/grade_provider.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/providers/resource_provider.dart';
import 'presentation/providers/announcement_provider.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/signup_page.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/pages/student/student_home_page.dart';
import 'presentation/pages/teacher/teacher_home_page.dart';
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
    
    // Auth
    final authLocalDataSource = AuthLocalDataSource(secureStorage: secureStorage);
    final authRemoteDataSource = AuthRemoteDataSource(dio: dio);
    final authRepository = AuthRepository(
      remoteDataSource: authRemoteDataSource,
      localDataSource: authLocalDataSource,
    );
    final authProvider = AuthProvider(
      authRemoteDataSource: authRemoteDataSource,
      secureStorage: secureStorage,
      dio: dio,
    );

    // Data sources
    final moduleRemoteDataSource = ModuleRemoteDataSource(dio: dio);
    final enrollmentRemoteDataSource = EnrollmentRemoteDataSource(dio: dio);
    final gradeRemoteDataSource = GradeRemoteDataSource(dio: dio);
    final sessionRemoteDataSource = SessionRemoteDataSource(dio: dio);
    final resourceRemoteDataSource = ResourceRemoteDataSource(dio: dio);
    final announcementRemoteDataSource = AnnouncementRemoteDataSource(dio: dio);

    // Repositories
    final moduleRepository = ModuleRepository(remoteDataSource: moduleRemoteDataSource);
    final enrollmentRepository = EnrollmentRepository(remoteDataSource: enrollmentRemoteDataSource);
    final gradeRepository = GradeRepository(remoteDataSource: gradeRemoteDataSource);
    final sessionRepository = SessionRepository(remoteDataSource: sessionRemoteDataSource);
    final resourceRepository = ResourceRepository(remoteDataSource: resourceRemoteDataSource);
    final announcementRepository = AnnouncementRepository(remoteDataSource: announcementRemoteDataSource);

    // Providers
    final moduleProvider = ModuleProvider(moduleRepository: moduleRepository);
    final enrollmentProvider = EnrollmentProvider(enrollmentRepository: enrollmentRepository);
    final gradeProvider = GradeProvider(gradeRepository: gradeRepository);
    final sessionProvider = SessionProvider(sessionRepository: sessionRepository);
    final resourceProvider = ResourceProvider(resourceRepository: resourceRepository);
    final announcementProvider = AnnouncementProvider(announcementRepository: announcementRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: moduleProvider),
        ChangeNotifierProvider.value(value: enrollmentProvider),
        ChangeNotifierProvider.value(value: gradeProvider),
        ChangeNotifierProvider.value(value: sessionProvider),
        ChangeNotifierProvider.value(value: resourceProvider),
        ChangeNotifierProvider.value(value: announcementProvider),
      ],
      child: MaterialApp(
        title: 'CampusConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.login,
        routes: {
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
