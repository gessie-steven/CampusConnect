import 'user_model.dart';

class AuthResponseModel {
  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;
  final String? message;

  AuthResponseModel({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.message,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access'] as String? ?? json['tokens']?['access'] as String?,
      refreshToken: json['refresh'] as String? ?? json['tokens']?['refresh'] as String?,
      user: json['user'] != null
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': user?.toJson(),
      'message': message,
    };
  }
}

