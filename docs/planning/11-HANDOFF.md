# 11 — Handoff: o que falta no app

> Escrito em 20/07/2026, no fim de uma rodada de código. Para quem pega isto
> **frio**: você não precisa ler os docs 08 e 10 inteiros pra começar. Precisa
> ler este, e ele diz quando abrir os outros.
>
> O que já foi feito está no git, com o porquê em cada mensagem de commit. Este
> documento é sobre o que **não** foi.
>
> **Atualizado ainda em 20/07/2026, na rodada seguinte** (merge + CI + APK). Os
> trechos vencidos foram corrigidos no lugar em vez de virarem apêndice, pra
> ninguém ler instrução morta. Onde a rodada nova **contradiz** a antiga, está
> marcado com ✅ ou ⚠️.

---

## 0. Onde as coisas estão

| | |
|---|---|
| **Branch do app** | ✅ `a11y-e-tablet` **mergeada na `main`** (`--no-ff`), branch preservada |
| **Branch do site** | já mergeada na `main` e **publicada** em `4yu.com.br/quanto-cobro/` |
| Versão | ✅ `0.8.0+10` (promovida no merge) |
| Testes | 273 passando, 26 arquivos · `flutter analyze` limpo |
| **CI** | ✅ existe agora: `.github/workflows/` com `ci.yml`, `build-apk.yml`, `build-aab.yml` |
| **APK** | ✅ buildado no CI **com R8**, 64 MB, 3 ABIs — nunca rodado em aparelho |
| Docs de referência | [08](08-PLANO-OFICIAL.md) = produto · [10](10-PLANO-A11Y-E-TABLET.md) = execução · [09](09-HANDOFF-FIREBASE-E-LOJA.md) = Firebase/loja |

**A primeira decisão já foi tomada:** a `a11y-e-tablet` foi mergeada na `main`
com `--no-ff`, depois de conferir os 273 testes e o `analyze` limpo. Não houve
PR — os commits já carregavam o porquê. A branch continua no repo.

---

## 1. A lacuna que nenhum teste fecha

> **Nada foi buildado nem rodado num aparelho.**

Tudo que existe está verificado por 273 testes e por render determinístico. Isso
cobre lógica, semântica e layout, e **não cobre**:

- **R8/minify, que quebra em RUNTIME e não no build.** Compila liso e crasha
  quando alguém abre a tela da classe removida.
- O comportamento do trilho e do mestre-detalhe **num tablet de verdade**, com
  rotação ao vivo e teclado abrindo.
- O ícone no lançador (foi conferido em PNG, não em aparelho).

⚠️ **Correção da rodada seguinte, sobre o R8.** Duas coisas que a versão
original deste doc errou:

1. **R8 não estava sequer ligado.** O `build.gradle.kts` não tinha
   `isMinifyEnabled`, então o medo acima descrevia um risco que ainda não
   existia. Agora está ligado (com regras em `android/app/proguard-rules.pro`),
   porque um APK sem R8 não provaria nada sobre o AAB que vai pra Play.
2. **O PDF da proposta é imune ao R8.** R8 só mexe em bytecode JVM; o pacote
   `pdf` é pure-Dart e vira AOT nativo. Quem pode quebrar nesse fluxo é o
   **`share_plus`** (FileProvider + activity result, lado Kotlin) — ou seja, a
   hora de **compartilhar**, não a de gerar. Ele tem bloco próprio no
   `proguard-rules.pro` por isso.

O raciocínio de fundo continua valendo: é um caminho por onde ninguém passa por
acidente, então é o candidato natural a só falhar com usuário real. Só mudou
**qual metade** dele é frágil.

O playbook da casa proíbe build local em WSL (derruba a máquina, ~11 GB). O
caminho é o CI — ✅ que agora existe (`build-apk.yml`, sem secret nenhum).

Se o compartilhamento quebrar no aparelho, rode o mesmo workflow com
`minify=false`: se aí funcionar, a causa é regra de keep faltando, e você tem o
culpado isolado em um run.

Até alguém abrir isso num aparelho, trate a rodada como **"verde nos testes e no
build, não verificada em hardware"**.

---

## 2. O que falta, em ordem

### 2.1 Bloqueado em passo humano (não dá pra começar)

| # | O quê | Destrava |
|---|---|---|
| 0 | ⚠️ Gerar a **keystore de upload** e pôr os 4 secrets no GitHub | o AAB da Play |
| 1 | Criar o projeto **Firebase**, deixando ele criar a própria propriedade GA4 | passos 3 e 4 |
| 2 | GCP → IAM → `Firebase Admin` pra `claude-automation@yu-automation.iam.gserviceaccount.com` | idem |
| 3 | Criar o app na **Play Console** | billing, ficha, Data Safety |
| 4 | Criar a **assinatura** mensal (ID irreversível) + testador de licença | o código do billing |

Detalhe de 1 a 4 em [10 §6.2](10-PLANO-A11Y-E-TABLET.md).

**O passo 0 não estava neste doc e é o mais irreversível de todos.** O
`build.gradle.kts` assinava o release com a **chave de debug** (o `TODO:` do
template ainda estava no arquivo) e nenhuma keystore existia pra
`com.fouryuapps.quantocobro`. Hoje o gradle lê `android/key.properties` e só cai
pro debug quando ele falta — que é o estado atual.

Perder essa keystore **depois** de publicar significa nunca mais conseguir
atualizar o app. Gere uma vez, e guarde backup fora desta máquina:

```bash
keytool -genkey -v -keystore ~/.android-keystores/quantocobro-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Depois, em Settings → Secrets and variables → Actions: `KEYSTORE_BASE64`
(`base64 -w0` do `.jks`), `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`. O
`build-aab.yml` falha de propósito, com mensagem explícita, enquanto não
existirem — e confere no fim se o AAB saiu com chave de debug, porque descobrir
isso no upload custa uma rodada inteira.

### 2.2 Código, assim que o humano destravar

**a) Play Billing — é o único bloqueio real de lançamento.**

Hoje não existe: `in_app_purchase` não está no `pubspec.yaml`, e
`core/billing/entitlement.dart` é uma flag booleana em `SharedPreferences`. Dá
pra virar Pro sem pagar.

Dá pra escrever ~90% antes do passo humano (dependência, serviço,
`queryPurchases` no boot, restaurar, ligar no `EntitlementRepository`), mas fica
**intestável** até a assinatura existir no console, porque o ID do produto é
irreversível e tem que bater. Escrever contra um produto que não existe é
escrever no escuro; a decisão de fazer isso é sua.

⚠️ **É assinatura, não compra única.** O [08 §9.2](08-PLANO-OFICIAL.md) decidiu
mensal de R$ 6,90. O playbook da casa fala em "compra vitalícia + Restaurar
compras" porque foi escrito a partir do Deixei Aqui: **aqui não se aplica**. O
que vale é `queryPurchases` no boot, período de graça e tratamento de renovação
falha.

**b) Firebase, depois dos passos 1 e 2.** A camada de telemetria já existe e os
eventos já disparam nos lugares certos (`core/telemetry/`). Falta só o destino:
registrar o app Android, versionar o `google-services.json` (ele **não** é
segredo, vai dentro do APK), ligar `firebase_core`/`analytics`/`crashlytics` e
trocar **uma linha** no `main.dart`, a instância `telemetry`. Nenhum call site
muda.

⚠️ Sem o `google-services.json`, o `firebase_core` não sobe e o app morre no
boot. É o mesmo tipo de crash que o `MobileAdsInitProvider` causou uma vez (está
registrado no `pubspec.yaml`).

**c) Subir a versão.** ✅ Feito: `0.8.0+10`. Minor porque a rodada carrega
feature de usuário (trilho, mestre-detalhe, os P0 de acessibilidade), não só
correção. Continua valendo pras próximas: promova **antes** de mandar build de
teste, senão dois APKs diferentes circulam com o mesmo número.

### 2.3 Polimento que ficou por último, de propósito

- **P2-2, P2-5, P2-6** foram feitos. **P2-7 (moeda falada) fica fora**, seguindo
  a recomendação da própria auditoria: é rigor que atrasa lançamento pra
  consertar um problema que talvez não exista. Se aparecer reclamação real de
  leitor de tela lendo "R$ 1.234" errado, o lugar é `common/money.dart`.
- Dois nits que não valem commit sozinhos: `onPerfilTap ?? () {}` em
  `core/ui/hero_value_card.dart` é um fallback que nunca dispara, e o iPad está
  sem multi-janela (`UIApplicationSupportsMultipleScenes: false`) — mas iOS não
  é o alvo de lançamento.

---

## 3. Decisões já tomadas. Não reabra sem motivo novo

Cada uma destas custou investigação. Se você for contra alguma, tudo bem, mas
saiba o que está desfazendo.

**O `R$` no ícone fica.** A pergunta "mas o app é multi-moeda, faz sentido?"
já foi feita e checada: `moneyBRL` é usado em **toda saída** do app (reserva,
cofre, totais, histórico, proposta). As outras moedas são só **entrada** ("Marina
cobrando em USD") e o FX converte pra real. O motor é MEI, DAS, carnê-leão,
INSS, e o lançamento é na Play brasileira. Tirar o `R$` deixaria o ícone mais
genérico, não mais preciso.

**A grade de 2 colunas nos Trabalhos foi substituída pelo mestre-detalhe.** Ela
era o plano B do [10 §4.4](10-PLANO-A11Y-E-TABLET.md); o plano A não custou
caro. As duas juntas não fazem sentido: com a lista em 380dp, duas colunas de
card virariam duas tiras de 180dp.

**Nem todo sobrolho virou cabeçalho.** A auditoria pedia `header: true` em
todos; o app tem dois tipos que parecem iguais na tela e são opostos na fala.
Seção ("ENTRADAS") é lugar pra onde se pula e virou `SecaoTitulo`; sobrancelha
de valor ("SEU VALOR-HORA") é o nome do número logo abaixo, que já carrega essa
frase no rótulo. Onze viraram, nove ficaram. O raciocínio está no doc de
`core/ui/secao_titulo.dart`.

**A marca mudou de propósito:** o arco esmeralda foi de 260° pra 240°. O ouro
encostava no verde porque ninguém tinha contado as pontas redondas
(`StrokeCap.round` come ~9,3° de arco por ponta; a fresta esquerda tinha 12°
brutos, ou seja fechava antes de existir). Isso vale no splash e no cabeçalho
também, e é o certo: o defeito era da marca, o ícone só foi onde ficou óbvio.

---

## 4. As ferramentas que esta rodada deixou

Três geradores em `test/ferramentas/`. **Nenhum roda no `flutter test` normal**
(o nome não termina em `_test.dart`, então o glob não pega). São ferramentas de
produção de arte, não asserções sobre o app: no CI, quebrariam o build a cada
pixel mudado.

```bash
flutter test test/ferramentas/prints_loja.dart --update-goldens   # 5 capturas da ficha
flutter test test/ferramentas/icone_app.dart   --update-goldens   # ícone: 5+5 densidades + 512 da Play
flutter test test/ferramentas/og_site.dart     --update-goldens   # cartão 1200x630 do site
```

**A armadilha que custou tempo e vai custar de novo:** render em `flutter test`
usa a fonte **Ahem** por padrão, então todo texto vira caixa preta, e os
**ícones** vêm do cache do SDK, não do `assets/` — sem carregar o
`MaterialIcons-Regular.otf` toda `Icon()` sai como quadrado vazio. Os três
arquivos já carregam o que precisam; se você criar um quarto, copie o
`_carregarFontes` de um deles.

Se mexer na marca ou nas telas, **rode os três de novo** e copie o `icon.png` e
o `og.png` pro repo `website` (eles nascem aqui porque a marca mora aqui).

---

## 5. Armadilhas do caminho, curtas

- **`google-services.json` não é segredo.** Versione. Sem ele, clone limpo não
  compila. ✅ O `.gitignore` **bloqueava** esse arquivo, contradizendo esta
  linha; a entrada foi removida e trocada por um comentário explicando o porquê.
- **Build local derruba a máquina** (WSL, ~11 GB). O caminho é o CI — ✅ que
  agora existe neste repo. Antes não existia: este doc dizia "o caminho é o CI"
  assumindo a infra do **Deixei Aqui**, e `.github/` aqui estava vazio.
- **12 testadores × 14 dias é por APP**, não por conta. As mesmas pessoas
  servem, mas precisam entrar na faixa deste app e o relógio zera. **Teste
  interno não conta**, tem que ser fechado.
- **Caminho absoluto do `.secrets/`**: em casa o usuário é `gabfelix`, no
  trabalho `gabrielbarbosa`. Trocou de máquina, corrija os caminhos ou tudo
  falha com "arquivo não encontrado" e você procura bug no lugar errado.
- **O console mente.** Prove no ar: `curl` na URL, e o evento de telemetria
  chegando na propriedade GA4 **do app**, nunca a do site.
- **A política é rascunho** e precisa de olhada jurídica antes da ficha. Ela foi
  corrigida nesta rodada (declarava AdMob depois de o anúncio ter sido removido),
  mas corrigir ≠ validar.

---

## 6. O que NÃO se aplica a este app

Escrito pra você não perder tempo procurando: sem localização, sem mapa, sem
foreground service, sem câmera, sem áudio, **sem anúncio**. Logo: sem vídeo de
FGS, sem declaração de localização em segundo plano, sem UMP, sem `MAPS_API_KEY`.

A única permissão do app é `INTERNET`, e ela existe pela cotação de câmbio.

Isso deixa o **Data Safety bem mais enxuto** do que o do Deixei Aqui: só o que
Firebase Analytics e Crashlytics coletam, e com o detalhe a favor de a
telemetria ser **opt-in de verdade**, desligada por padrão.

---

## 7. Se você só tem uma hora

Os passos 1 e 2 da versão original (merge e versão) ✅ já foram feitos, e o APK
já está buildado. Sobrou o que exige mão humana e hardware:

1. **Instale o APK e abra a proposta.** O artefato sai do workflow
   `build-apk.yml` (aba Actions → Run workflow → baixar o artifact). É assinado
   com chave de debug, então o aparelho pede "instalar de fontes desconhecidas".
   Teste **compartilhar** o PDF, não só gerar — ver a correção no §1.
2. **Tablet de verdade:** trilho e mestre-detalhe, girando ao vivo, com teclado
   abrindo.
3. **Gere a keystore** (§2.1 passo 0). É o único item da lista que fica pior
   quanto mais tarde for feito.

Isso fecha a lacuna do §1, que é a única coisa que separa "verde nos testes" de
"funciona".
