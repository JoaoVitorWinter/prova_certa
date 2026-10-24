import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'models/usuario.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProvaCertaApp());
}

class ProvaCertaApp extends StatelessWidget {
  final Widget? homeOverride;
  final Stream<User?>? authStateStream;
  final AuthService? authService;

  const ProvaCertaApp({
    super.key,
    this.homeOverride,
    this.authStateStream,
    this.authService,
  });

  @override
  Widget build(BuildContext context) {
    final stream = authStateStream ??
        (Firebase.apps.isNotEmpty
            ? FirebaseAuth.instance.authStateChanges()
            : null);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: homeOverride ??
          (stream != null
              ? StreamBuilder<User?>(
                  stream: stream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        backgroundColor: Color(0xFFF4F6FA),
                        body: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF713CEB),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasData && snapshot.data != null) {
                      final service = authService ?? AuthService();
                      return StreamBuilder<Usuario?>(
                        stream: service.monitorarPerfil(snapshot.data!.uid),
                        builder: (context, perfilSnapshot) {
                          if (perfilSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Scaffold(
                              backgroundColor: Color(0xFFF4F6FA),
                              body: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF713CEB),
                                ),
                              ),
                            );
                          }
                          final perfil = perfilSnapshot.data;
                          if (perfil != null &&
                              perfil.nome.trim().isNotEmpty &&
                              perfil.email.trim().isNotEmpty) {
                            return HomeScreen(authService: authService);
                          }
                          return LoginScreen(authService: authService);
                        },
                      );
                    }

                    return const LoginScreen();
                  },
                )
              : const LoginScreen()),
    );
  }
}
