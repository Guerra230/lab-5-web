import 'package:moviles_auth/features/auth/domain/entities/auth_user.dart';
import 'package:moviles_auth/features/auth/domain/entities/profile.dart';
import 'package:moviles_auth/features/auth/domain/exceptions/auth_failure.dart';
import 'package:moviles_auth/features/auth/domain/repository/auth_repository.dart';
import 'package:moviles_auth/features/auth/domain/repository/profile_repository.dart';

class SignInUseCase {
  final AuthRepository _auth;
  final ProfileRepository _profiles;

  SignInUseCase(this._auth, this._profiles);

  Future<({AuthUser user, Profile profile})> call({
    required String email,
    required String password,
  }) async {
    final user = await _auth.signIn(email: email, password: password);
    try {
      final profile = await _profiles.getProfile(user.id);
      return (user: user, profile: profile);
    } on Exception {
      await _auth.signOut();
      throw const AuthFailure('No se encontró tu perfil');
    }
  }
}
