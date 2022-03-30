import 'package:box3/screens/signin.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Box',
      home: MyLoginPage(),
      // home: MyLoginPage(),
    );
  }
}
