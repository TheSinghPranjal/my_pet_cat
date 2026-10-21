import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/cat_game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyPetCatApp());
}

class MyPetCatApp extends StatelessWidget {
  const MyPetCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Pet Cat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2236B5)),
      home: const CatGameScreen(),
    );
  }
}
