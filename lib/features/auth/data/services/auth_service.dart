import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../models/user_model.dart';

class AuthService {
  static const demoEmail = 'demo@brandvault.dev';
  static const demoPassword = 'Demo1234!';

  Future<UserModel> signUp({required String email, required String password}) =>
      _authenticate(Endpoints.signUp, email, password);

  Future<UserModel> signIn({required String email, required String password}) =>
      _authenticate(Endpoints.signIn, email, password);

  Future<UserModel> continueAsDemo() => signIn(email: demoEmail, password: demoPassword);

  Future<void> signOut() => AppApiClient.clearToken();

  Future<UserModel> _authenticate(String path, String email, String password) async{
    if (AppApiClient.useMock){

      await Future.delayed(const Duration(microseconds: 300));
      await AppApiClient.setToken('mock-jwt-token');
      return UserModel(id: 'mock-user-1', email: email.trim());
    }

    try{
      final json = await AppApiClient.post(path,
      body: {'email': email.trim(), 'password': password},
      );

      await AppApiClient.setToken(json['token'] as String);
      return UserModel.fromJson(json['user'] as Map<String,dynamic>);
    }on AppException catch (e){
      if (e.statusCode == 401) {
        throw AppException('Incorrect email or password.', statusCode: 401);
      }
      rethrow;
    }
  }
}