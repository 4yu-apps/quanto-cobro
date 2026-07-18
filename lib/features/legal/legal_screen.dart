import 'package:flutter/material.dart';

import 'legal_texts.dart';

/// Política de Privacidade + Termos, mostrados no app (PADRÃO 4YU §Legal).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidade e Termos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(LegalTexts.privacidade, style: t.bodyMedium),
          const Divider(height: 32),
          Text(LegalTexts.termos, style: t.bodyMedium),
        ],
      ),
    );
  }
}
