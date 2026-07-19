import '../../core/config/app_config.dart';

/// Texto-fonte de Política de Privacidade e Termos (PADRÃO 4YU §Legal). Mostrado
/// no app (Configurações) e espelhado na versão hospedada em
/// `${AppConfig.webHost}${AppConfig.webBasePath}/privacidade` (URL exigida pela Play).
///
/// RASCUNHO: revisar/validar juridicamente antes de publicar. A base do Deixei
/// Aqui (LGPD: responsável, permissões, direitos, exclusão, AdMob) deve ser reusada.
abstract final class LegalTexts {
  static const String privacidade =
      '''
Política de Privacidade · ${AppConfig.appName}

Este app é local-first: seus dados de renda, custos e cálculos ficam NO SEU
APARELHO. Não há cadastro, login nem servidor nosso guardando essas informações.

O que NÃO coletamos: nome, e-mail, renda, valores digitados. Nada disso sai do
aparelho.

O que pode ser coletado (opt-in, você controla em Configurações): métricas
anônimas de uso e estabilidade (crash), para melhorar o app. Você pode desligar
a qualquer momento.

Anúncios: o app pode exibir anúncios (Google AdMob), um terceiro que pode coletar
identificadores do dispositivo conforme a política dele.

Seus direitos (LGPD): apagar seus dados a qualquer momento em Configurações
("apagar meus dados") remove tudo do aparelho.

Contato: ${AppConfig.contactEmail}
''';

  static const String termos =
      '''
Termos de Uso · ${AppConfig.appName}

Os números do app são ESTIMATIVAS DE PLANEJAMENTO para ajudar você a decidir
preço. Não são consultoria fiscal nem declaração de imposto. As alíquotas
(MEI/DAS, Simples, IRPF, INSS) mudam e variam por caso; confirme nas fontes
oficiais da Receita Federal antes de recolher tributos.

O app é fornecido "como está". Use as estimativas como apoio à decisão, não como
valor devido oficial.

Contato: ${AppConfig.contactEmail}
''';
}
