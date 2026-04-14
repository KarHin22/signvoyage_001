import 'package:flutter/material.dart';

class SignTranslatorScreen extends StatelessWidget {
  const SignTranslatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Translator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 80,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('Sign-to-Text Vision',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Student 1 - Replace this placeholder',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
