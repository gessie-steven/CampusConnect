class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://localhost:8000/api/';
  static const String apiVersion = '/v1';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // Routes
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String studentHomeRoute = '/student/home';
  static const String teacherHomeRoute = '/teacher/home';
  static const String adminHomeRoute = '/admin/home';
}

