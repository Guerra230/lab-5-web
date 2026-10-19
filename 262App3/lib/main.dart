import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:moviles_auth/features/auth/data/repository/auth_repository_impl.dart';
import 'package:moviles_auth/features/auth/data/repository/profile_repository_impl.dart';
import 'package:moviles_auth/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:moviles_auth/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:moviles_auth/features/auth/domain/repository/auth_repository.dart';
import 'package:moviles_auth/features/auth/domain/repository/profile_repository.dart';
import 'package:moviles_auth/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:moviles_auth/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:moviles_auth/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:moviles_auth/features/home/ui/screens/home_arguments.dart';
import 'package:moviles_auth/features/home/ui/screens/home_screen.dart';
import 'package:moviles_auth/features/login/ui/bloc/login_bloc.dart';
import 'package:moviles_auth/features/login/ui/screens/login_screen.dart';
import 'package:moviles_auth/features/register/ui/bloc/register_bloc.dart';
import 'package:moviles_auth/features/register/ui/screens/register_screen.dart';
import 'package:moviles_auth/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rarrcvlaiwufmntwndrk.supabase.co',
    publishableKey: 'sb_publishable_euygOGr-FwLMFd_X69ZA1w_79nnxZGv',
  );

  final client = Supabase.instance.client;
  runApp(
    App(
      authRepository: AuthRepositoryImpl(SupabaseAuthDataSource(client)),
      profileRepository: ProfileRepositoryImpl(
        SupabaseProfileDataSource(client),
      ),
    ),
  );
}

class App extends StatelessWidget {
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  const App({
    super.key,
    required this.authRepository,
    required this.profileRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moviles Auth',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      initialRoute: '/login',
      routes: {
        '/login': (_) => BlocProvider(
          create: (_) =>
              LoginBloc(SignInUseCase(authRepository, profileRepository)),
          child: const LoginScreen(),
        ),
        '/register': (_) => BlocProvider(
          create: (_) =>
              RegisterBloc(SignUpUseCase(authRepository, profileRepository)),
          child: const RegisterScreen(),
        ),
        '/home': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as HomeArguments;
          return HomeScreen(
            username: args.profile.username,
            fullName: args.profile.fullName,
            email: args.email,
            signOut: SignOutUseCase(authRepository),
          );
        },
      },
    );
  }
}
