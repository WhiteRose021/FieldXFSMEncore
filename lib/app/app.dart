import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'routes.dart';

class FieldXApp extends StatelessWidget {
  const FieldXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldX FSM',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.getRoutes(),
      initialRoute: AppRoutes.login,
    );
  }
}
