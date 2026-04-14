import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_shell.dart';

class SignVoyageApp extends StatelessWidget {
  const SignVoyageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignVoyage',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
