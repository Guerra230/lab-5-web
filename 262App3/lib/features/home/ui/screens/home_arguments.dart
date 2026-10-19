import 'package:moviles_auth/features/auth/domain/entities/profile.dart';

class HomeArguments {
  final Profile profile;
  final String email;

  const HomeArguments({required this.profile, required this.email});
}
