import 'package:hive_flutter/adapters.dart';
import 'package:tapes/box.dart';
import 'package:tapes/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tapes/note.dart';

void main() async{
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color.fromRGBO(255, 249, 228, 100),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
 await Hive.initFlutter();
 Hive.registerAdapter(NoteAdapter());

 box = await Hive.openBox('notebox');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext build) {
    return const MaterialApp(home: InderPage());
  }
}
