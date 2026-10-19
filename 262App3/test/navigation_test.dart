import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moviles_auth/features/auth/domain/entities/auth_user.dart';
import 'package:moviles_auth/features/auth/domain/entities/profile.dart';
import 'package:moviles_auth/features/auth/domain/exceptions/auth_failure.dart';
import 'package:moviles_auth/features/auth/domain/repository/auth_repository.dart';
import 'package:moviles_auth/features/auth/domain/repository/profile_repository.dart';
import 'package:moviles_auth/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:moviles_auth/main.dart';

class FakeAuthRepository implements AuthRepository {
  final accounts = <String, (String, String)>{};
  int signOutCalls = 0;

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async {
    if (accounts.containsKey(email)) {
      throw const AuthFailure('User already registered');
    }
    final id = 'uid-${accounts.length + 1}';
    accounts[email] = (id, password);
    return AuthUser(id: id, email: email);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final account = accounts[email];
    if (account == null || account.$2 != password) {
      throw const AuthFailure('Invalid login credentials');
    }
    return AuthUser(id: account.$1, email: email);
  }

  @override
  Future<void> signOut() async => signOutCalls++;
}

class FakeProfileRepository implements ProfileRepository {
  final rows = <String, Profile>{};
  bool failOnCreate = false;

  @override
  Future<void> createProfile(Profile profile) async {
    if (failOnCreate) {
      throw const AuthFailure('permission denied for table profiles');
    }
    rows[profile.id] = profile;
  }

  @override
  Future<Profile> getProfile(String id) async {
    final profile = rows[id];
    if (profile == null) throw const AuthFailure('not found');
    return profile;
  }
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final button = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _goToRegister(WidgetTester tester) async {
  await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
  await tester.pumpAndSettle();
  expect(find.text('Crea tu cuenta'), findsOneWidget);
}

Future<void> _fillRegister(
  WidgetTester tester, {
  String email = 'ana@icesi.edu.co',
  String confirm = '123456',
}) async {
  await tester.enterText(find.byType(TextField).at(0), 'ana');
  await tester.enterText(find.byType(TextField).at(1), 'Ana Gómez');
  await tester.enterText(find.byType(TextField).at(2), email);
  await tester.enterText(find.byType(TextField).at(3), '123456');
  await tester.enterText(find.byType(TextField).at(4), confirm);
}

void main() {
  late FakeAuthRepository auth;
  late FakeProfileRepository profiles;

  setUp(() {
    auth = FakeAuthRepository();
    profiles = FakeProfileRepository();
  });

  Widget app() => App(authRepository: auth, profileRepository: profiles);

  testWidgets('sign up rejects passwords that do not match, then registers', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await _goToRegister(tester);

    await _fillRegister(tester, confirm: '654321');
    await _tapButton(tester, 'Registrarme');
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(auth.accounts, isEmpty, reason: 'el Bloc ni se entera');

    await tester.enterText(find.byType(TextField).at(4), '123456');
    await _tapButton(tester, 'Registrarme');

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Ana Gómez'), findsWidgets);
    expect(find.text('ana@icesi.edu.co'), findsOneWidget);
    expect(profiles.rows['uid-1']?.username, 'ana');
  });

  testWidgets('registering the same email twice shows the error', (
    tester,
  ) async {
    await auth.signUp(email: 'ana@icesi.edu.co', password: 'x');
    await tester.pumpWidget(app());
    await _goToRegister(tester);

    await _fillRegister(tester);
    await _tapButton(tester, 'Registrarme');

    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('User already registered'), findsOneWidget);
    expect(profiles.rows, isEmpty, reason: 'el perfil ni se intenta');
  });

  testWidgets('sign in goes to profile and sign out comes back', (
    tester,
  ) async {
    final user = await auth.signUp(email: 'ana@icesi.edu.co', password: '123456');
    profiles.rows[user.id] = Profile(
      id: user.id,
      username: 'ana',
      fullName: 'Ana Gómez',
    );
    await tester.pumpWidget(app());
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);

    await _tapButton(tester, 'Iniciar sesión');
    expect(find.text('Escribe tu correo y tu contraseña'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'ana@icesi.edu.co');
    await tester.enterText(find.byType(TextField).at(1), 'mala');
    await _tapButton(tester, 'Iniciar sesión');
    expect(find.text('Invalid login credentials'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '123456');
    await _tapButton(tester, 'Iniciar sesión');
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('ana@icesi.edu.co'), findsOneWidget);
    expect(find.text('@ana'), findsOneWidget);

    await _tapButton(tester, 'Cerrar sesión');
    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(auth.signOutCalls, 1);
  });

  test('SignUpUseCase signs out when the profile cannot be saved', () async {
    profiles.failOnCreate = true;
    final signUp = SignUpUseCase(auth, profiles);

    await expectLater(
      signUp(
        username: 'ana',
        fullName: 'Ana Gómez',
        email: 'ana@icesi.edu.co',
        password: '123456',
      ),
      throwsA(isA<AuthFailure>()),
    );
    expect(auth.signOutCalls, 1);
  });
}
