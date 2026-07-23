import '../../core/config/app_config.dart';

/// Texto-fonte de Política de Privacidade e Termos (PADRÃO 4YU §Legal). Mostrado
/// no app (Ajustes → Privacidade e Termos) e espelhado na versão hospedada em
/// `${AppConfig.webHost}${AppConfig.webBasePath}/privacidade` (URL exigida pela Play).
///
/// **As duas versões têm que dizer a MESMA coisa.** Divergência entre a política
/// hospedada e a do app é motivo de reprovação na Play, e já aconteceu nesta
/// conta: a página falava de Bluetooth e localização em segundo plano que o app
/// não tinha mais.
///
/// A auditoria de 23/07/2026 achou a divergência de novo, no sentido inverso e
/// mais perigoso: a página hospedada tinha 14 seções e este arquivo tinha oito
/// parágrafos. O que faltava AQUI não era estilo, era conteúdo exigido — quem
/// recebe os dados (Google), a transferência internacional, a base legal, os
/// prazos de retenção, a assinatura Pro e a cláusula de crianças. Uma política
/// que promete menos do que a hospedada não é "mais enxuta": é uma segunda
/// política, contraditória com a primeira, dentro do mesmo produto.
///
/// Se for editar, edite **os dois lados na mesma sessão**. E confira os rótulos
/// contra a tela de verdade: o texto dizia "Configurações" enquanto a tela se
/// chama "Ajustes" (`config_screen.dart`) — política que descreve um botão que
/// não existe com esse nome é instrução que não se consegue seguir.
///
/// RASCUNHO: revisar/validar juridicamente antes de publicar.
abstract final class LegalTexts {
  static const String privacidade =
      '''
Política de Privacidade · ${AppConfig.appName}

O ${AppConfig.appName} foi feito pra funcionar offline e respeitar a sua
privacidade. Esta política explica, de forma clara, quais dados o app usa, pra
quê, e quais são os seus direitos. Ao usar o app, você concorda com o descrito
aqui.

1. Quem é o responsável

O aplicativo ${AppConfig.appName} é desenvolvido pela ${AppConfig.parentBrand}.
Pra qualquer assunto sobre seus dados (dúvidas, solicitações ou exercício de
direitos), o contato é ${AppConfig.contactEmail}. Esse mesmo endereço é o nosso
canal de atendimento ao titular de dados. Como desenvolvedor de pequeno porte,
seguimos a Resolução CD/ANPD nº 2/2022, que dispensa a indicação formal de um
Encarregado (DPO) e pede, no lugar, um canal direto com você. É este.

2. O princípio: seus dados ficam no seu aparelho

Tudo o que você cria no app fica armazenado somente no seu aparelho: a sua renda
desejada, os seus custos, as suas horas, os valores que você recebe, o nome dos
seus clientes, as suas propostas e a sua marca. Não temos servidor recebendo
esses dados, não os acessamos, não os copiamos e não conseguimos vê-los. Não é
preciso criar conta nem fazer login.

Isso vale pro conteúdo que você cria, e é a regra principal do app. Existe uma
categoria diferente e menor: dados de uso e de falha, que ajudam a consertar
problemas. Eles são opcionais, ficam desligados até você ligar, e nunca
acompanham os seus valores. O item 4 explica exatamente o quê, quem recebe e
como desligar.

3. Este app não exibe anúncios

O ${AppConfig.appName} não tem anúncios e não integra nenhuma rede de
publicidade. Não existe SDK de anúncio no app, e o seu identificador de
publicidade não é lido. A receita do app vem da assinatura Pro, descrita no
item 6.

4. Dados de uso e de falha (opcionais, desligados por padrão)

Se você ligar a opção em Ajustes, o app passa a enviar duas coisas pros serviços
do Google (Google Analytics para Firebase e Firebase Crashlytics), o que pode
envolver transferência pra servidores fora do Brasil:

· Uso: eventos que registram QUE uma ação aconteceu (você começou um cálculo,
  chegou ao passo 3, registrou um recebimento, abriu o glossário), além de dados
  técnicos do aparelho, como modelo, versão do Android, idioma e país.

· Falha: quando o app trava, um relatório com o ponto do código onde quebrou, o
  modelo do aparelho e a versão do Android. É como descobrimos que o app falhou
  no seu celular sem que você precise nos contar.

O limite é rígido e vale a pena ler: nenhum desses eventos carrega dinheiro,
nome, cliente ou texto digitado. Saber que uma pessoa registrou um recebimento é
legítimo; saber quanto ela recebeu não é, e o app não envia. Existe um teste
automatizado no nosso código que falha se alguém tentar adicionar um parâmetro
que pareça dado pessoal.

Como ligar ou desligar: Ajustes, na seção Privacidade. Vem desligado. Ligando ou
desligando, o app continua funcionando igual, sem nenhuma função a menos.

Base legal e transferência internacional: a base pra tratar esses dados de uso e
falha é o seu consentimento (Art. 7º, I, da LGPD), dado ao ligar a opção. Como o
Google processa em servidores fora do Brasil, isso é uma transferência
internacional, feita com base no seu consentimento específico e informado
(Art. 33, VIII) e nas cláusulas contratuais padrão adotadas pelo Google
(Art. 33, II). Manter a opção desligada evita essa transferência. O funcionamento
do app e a assinatura Pro, por sua vez, se apoiam na execução do contrato a seu
pedido (Art. 7º, V).

5. Acesso à internet e cotação de câmbio

O app funciona offline. A única conexão que ele faz por conta própria é buscar a
cotação de câmbio, e apenas quando você registra um recebimento em moeda
estrangeira. A consulta vai pra um serviço público de cotações (open.er-api.com)
e leva somente a sigla da moeda, por exemplo USD. Nenhum valor seu é enviado
nessa consulta, e ela não identifica você.

A permissão de internet do app existe por causa disso e do envio opcional do
item 4. Se você nunca usar moeda estrangeira e mantiver o item 4 desligado, o app
não faz nenhuma chamada de rede.

6. Assinatura Pro

A assinatura é processada pela loja (Google Play). Não recebemos nem armazenamos
os dados do seu cartão. A loja cuida da cobrança, da renovação e do cancelamento.
No app, guardamos localmente apenas o estado "Pro ativo".

7. Com quem compartilhamos

Não vendemos e não alugamos seus dados pessoais. Os únicos terceiros envolvidos
são: o Google (Analytics para Firebase e Crashlytics, somente se você ligar o
item 4), o serviço público de cotações do item 5, e a própria loja (processamento
da assinatura). Nenhum deles recebe o conteúdo que você cria no app.

8. Por quanto tempo guardamos

Como os dados ficam no seu aparelho, eles permanecem enquanto você quiser. Você
pode apagar tudo a qualquer momento ou desinstalar o app, e isso remove os dados
locais.

Os dados de uso e de falha do item 4, se você os tiver ligado, ficam com o Google
e seguem os prazos dele: os de uso, por 14 meses; os relatórios de falha, por
cerca de 90 dias. Depois disso são apagados automaticamente.

9. Seus direitos (LGPD)

A Lei Geral de Proteção de Dados (Lei 13.709/2018) garante a você, entre outros,
os direitos de acesso, correção, exclusão, portabilidade, informação sobre
compartilhamento e revogação de consentimento. Como praticamente todos os dados
são locais e ficam sob o seu controle direto no aparelho, você exerce a maior
parte desses direitos dentro do próprio app. Pra qualquer outra solicitação,
escreva pra ${AppConfig.contactEmail}.

10. Como excluir todos os seus dados

Você pode: (a) tocar em "Apagar meus dados" em Ajustes, que remove cálculos,
trabalhos, recebimentos, propostas e marca do aparelho; ou (b) desinstalar o app,
o que remove todos os dados locais. Não é necessário nos contatar pra isso.

Pra pedir a exclusão dos dados de uso e falha coletados pelo Google, caso você os
tenha ligado, veja a página
${AppConfig.webHost}${AppConfig.webBasePath}/excluir-dados.

11. Crianças

O app não é direcionado a menores de 13 anos e não coleta intencionalmente dados
de crianças.

12. Segurança

Os dados ficam na área privada do app no seu aparelho, protegida pelo sistema
operacional. Recomendamos manter o aparelho com bloqueio de tela e o sistema
atualizado.

13. Alterações

Podemos atualizar esta política pra refletir melhorias ou exigências legais. A
versão vigente fica sempre disponível dentro do app e na página
${AppConfig.webHost}${AppConfig.webBasePath}/privacidade.

14. Contato

Dúvidas ou solicitações sobre privacidade: ${AppConfig.contactEmail}.
''';

  static const String termos =
      '''
Termos de Uso · ${AppConfig.appName}

Ao usar o ${AppConfig.appName}, você concorda com estes Termos de Uso. Se não
concordar, não use o app.

1. O que o app faz

O ${AppConfig.appName} ajuda você a decidir preço: calcula quanto vale a sua hora
a partir da renda que você quer, dos seus custos e das horas que você consegue
vender, e mostra quanto separar de imposto a cada recebimento. É uma ferramenta
de apoio à decisão.

2. Os números são estimativas, não são consultoria fiscal

Este é o ponto mais importante destes termos. Os valores do app são estimativas
de planejamento. Não são consultoria contábil, não são consultoria fiscal e não
são declaração de imposto. As alíquotas e regras (MEI e DAS, Simples Nacional,
IRPF, INSS, carnê-leão) mudam com o tempo e variam conforme a sua situação.

Confirme nas fontes oficiais da Receita Federal, ou com o seu contador, antes de
recolher qualquer tributo. Não nos responsabilizamos por tributo recolhido a
menor ou a maior com base nas estimativas do app.

3. Cotação de câmbio

A cotação vem de um serviço público de terceiros, é informativa e pode estar
defasada em relação à taxa que o seu banco ou a sua plataforma de pagamento
aplicar de fato. Use como referência, não como valor final.

4. Propostas geradas pelo app

A proposta em PDF é um documento que você gera e envia por sua conta. O conteúdo,
os valores e o compromisso assumido com o seu cliente são inteiramente seus. O
app não é parte da relação entre você e o seu cliente.

5. Elegibilidade

O app não é direcionado a menores de 13 anos. Ao usá-lo, você declara ter
capacidade pra aceitar estes termos.

6. Sem garantia

O app é fornecido "no estado em que se encontra", sem garantias de
disponibilidade, exatidão ou adequação a um fim específico.

7. Limitação de responsabilidade

Na máxima extensão permitida pela lei, não nos responsabilizamos por prejuízo
financeiro, perda de contrato, multa, autuação ou qualquer dano decorrente do uso
ou da impossibilidade de uso do app, inclusive decisões de preço tomadas com base
nas estimativas. O uso é por sua conta e risco.

8. Assinatura Pro

O Pro é uma assinatura recorrente, cobrada pela Google Play, que libera recursos
adicionais. A cobrança se renova automaticamente ao fim de cada período, pelo
preço vigente, até que você cancele. O cancelamento e eventuais reembolsos seguem
as regras da Google Play, e você gerencia a assinatura na sua conta da loja —
cancelar ali interrompe as próximas cobranças e o Pro continua até o fim do
período já pago. Preços e recursos podem mudar em versões futuras, com aviso
prévio na forma exigida pela loja.

9. Uso correto

Use o app de forma segura, legal e apenas para os fins a que se destina. É
proibido tentar burlar, copiar ou explorar o app de forma indevida, inclusive
tentar liberar recursos pagos sem a assinatura.

10. Privacidade

O tratamento de dados segue a nossa Política de Privacidade, que faz parte destes
termos.

11. Propriedade intelectual

A marca, o design e o código do app pertencem à ${AppConfig.parentBrand}. Você
recebe uma licença de uso pessoal, limitada, não exclusiva e intransferível. Os
documentos que você gera com o app (as suas propostas) são seus.

12. Alterações destes termos

Podemos atualizar estes termos. A versão vigente fica sempre disponível no app e
na página ${AppConfig.webHost}${AppConfig.webBasePath}/privacidade. O uso
continuado após mudanças significa concordância com a nova versão.

13. Lei aplicável e foro

Estes termos são regidos pelas leis do Brasil. Fica eleito o foro do domicílio do
usuário pra dirimir eventuais controvérsias, conforme a legislação de consumo.

14. Contato

Dúvidas: ${AppConfig.contactEmail}.
''';
}
