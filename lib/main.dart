import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khorcha/pages/home_page.dart';
import 'package:khorcha/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:khorcha/pages/login_status_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF03624C)),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: LoginStatusPage()
    );
  }
}


