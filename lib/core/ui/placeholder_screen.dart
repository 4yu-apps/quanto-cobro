import 'package:flutter/material.dart';

/// Placeholder de tela: a estrutura (rota + arquivo do feature) está pronta; o
/// conteúdo entra nas próximas etapas, guiado pela IA (planning/03).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Estrutura pronta. Conteúdo nas próximas etapas.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
