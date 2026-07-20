import '../../core/config/app_config.dart';

/// Texto-fonte de Política de Privacidade e Termos (PADRÃO 4YU §Legal). Mostrado
/// no app (Configurações) e espelhado na versão hospedada em
/// `${AppConfig.webHost}${AppConfig.webBasePath}/privacidade` (URL exigida pela Play).
///
/// **A versão do site sai DAQUI, nunca reescrita.** Divergência entre a política
/// hospedada e a do app é motivo de reprovação na Play, e já aconteceu nesta
/// conta: a página falava de Bluetooth e localização em segundo plano que o app
/// não tinha mais.
///
/// Aqui o defeito era o inverso, e igualmente caro: este texto declarava "o app
/// pode exibir anúncios (Google AdMob)" **depois** de o anúncio ter sido
/// removido na Fase 0 (ver `core/ads/ads.dart` pro número que motivou a
/// decisão). Declarar coleta que não existe erra em três frentes: desalinha o
/// Data Safety, entrega de graça a suspeita de rastreio, e joga fora o
/// argumento mais forte do produto, que é justamente não coletar nada.
///
/// RASCUNHO: revisar/validar juridicamente antes de publicar.
abstract final class LegalTexts {
  static const String privacidade =
      '''
Política de Privacidade · ${AppConfig.appName}

Este app é local-first: seus dados de renda, custos, trabalhos e cálculos ficam
NO SEU APARELHO. Não há cadastro, não há login, e não existe servidor nosso
guardando essas informações.

O que NÃO coletamos: seu nome, seu e-mail, sua renda, os valores que você
digita, o nome dos seus clientes. Nada disso sai do aparelho.

Anúncios: este app NÃO exibe anúncios e não usa rede de publicidade. Não há
identificador de publicidade sendo lido.

O que pode ser coletado, com a sua autorização: métricas anônimas de uso e de
estabilidade (falhas), pra descobrir onde o app trava ou confunde. É opt-in,
fica desligado até você ligar, e você desliga quando quiser em Configurações.
Esses eventos registram QUE uma ação aconteceu, nunca o valor envolvido: nenhum
deles carrega dinheiro, nome, cliente ou texto digitado.

Acesso à internet: o app funciona offline. A única conexão que ele faz é buscar
a cotação de câmbio, e só quando você registra um recebimento em moeda
estrangeira. A consulta vai pra um serviço público de cotações (open.er-api.com)
e leva apenas a sigla da moeda, por exemplo USD. Nenhum valor seu é enviado.

Seus direitos (LGPD): você apaga tudo a qualquer momento em Configurações, na
opção "apagar meus dados". Como os dados estão só no aparelho, apagar ali é
apagar de vez. Desinstalar o app também remove tudo.

Contato: ${AppConfig.contactEmail}
''';

  static const String termos =
      '''
Termos de Uso · ${AppConfig.appName}

Os números do app são ESTIMATIVAS DE PLANEJAMENTO pra ajudar você a decidir
preço. Não são consultoria fiscal nem declaração de imposto. As alíquotas
(MEI/DAS, Simples, IRPF, INSS) mudam e variam por caso; confirme nas fontes
oficiais da Receita Federal antes de recolher tributos.

A cotação de câmbio é informativa e vem de um serviço público de terceiros. Pode
estar defasada em relação à taxa que o seu banco aplicar.

O app é fornecido "como está". Use as estimativas como apoio à decisão, não como
valor devido oficial.

Contato: ${AppConfig.contactEmail}
''';
}
