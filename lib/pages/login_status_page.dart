import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:khorcha/pages/home_page.dart';
import 'package:khorcha/pages/login_page.dart';

class LoginStatusPage extends StatelessWidget {
  const LoginStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context,snapshot)  {
            if(snapshot.hasData) {
              return HomePage();
            }
            else {
              return LoginPage();
            }
          }
      ),
    );
  }
}
