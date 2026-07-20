# 09 — Handoff: Firebase + Play Console

> **Para o agente que for fazer isto.** Escrito em 19/07/2026. O dono cria a
> conta na Play Console e o projeto Firebase em 20/07, e quer resolver tudo
> numa tacada só.
>
> **O código já está pronto e esperando.** Nada aqui exige refatoração — só
> configuração, mais a troca de uma linha.

---

## 0. Antes de tudo: carregue os segredos

```bash
set -a && . /home/gabfelix/dev/4yu-apps/.secrets/4yu.env && set +a
```

Confirme que a service account está viva:

```bash
python3 -c "import json,os;print(json.load(open(os.environ['GOOGLE_APPLICATION_CREDENTIALS']))['client_email'])"
# esperado: claude-automation@yu-automation.iam.gserviceaccount.com
```

Leia `/home/gabfelix/dev/4yu-apps/CLAUDE.md` inteiro antes de tocar em GCP —
ele documenta o que a SA alcança, os escopos e as armadilhas já pagas.

---

## 1. Firebase — o que é passo HUMANO (não tente pela API)

**Service account não cria projeto GCP sem organização.** A API responde
`Service accounts cannot create projects without a parent`, e não existe papel
que resolva. Já verificado em 19/07: a SA só enxerga o projeto `deixei-aqui`.

O humano faz:

1. Criar o projeto Firebase do app. **Deixe o Firebase criar a propriedade GA4
   dele** — uma propriedade por produto, não uma pra tudo. Isso é regra da casa
   (`4yu-apps/CLAUDE.md`): dado misturado não se separa depois.
2. GCP → IAM → conceder **Firebase Admin** a
   `claude-automation@yu-automation.iam.gserviceaccount.com`.

Depois disso, o agente consegue o resto pela API.

---

## 2. Firebase — o que o AGENTE faz

1. Registrar o app Android. Package: **`com.fouryuapps.quantocobro`**
   (confirme em `android/app/build.gradle.kts`).
2. Baixar o `google-services.json` → `android/app/google-services.json`.
3. Adicionar ao `pubspec.yaml`: `firebase_core`, `firebase_analytics`,
   `firebase_crashlytics`.
4. Ligar o plugin gradle `com.google.gms.google-services` (e o do Crashlytics).
5. Implementar `TelemetryFirebase` em `lib/core/telemetry/` — a interface já
   existe em `telemetry.dart`, são 3 métodos.
6. **Trocar UMA linha** em `lib/main.dart`:
   ```dart
   telemetry = TelemetryNoOp();      // hoje
   telemetry = TelemetryFirebase();  // depois
   ```
   **Nenhum call site muda.** Os eventos já disparam nos lugares certos.

### ⚠️ A armadilha que já custou caro uma vez
O `pubspec.yaml` registra: o `MobileAdsInitProvider` **derrubou o app no boot**
em produção porque faltava config no `AndroidManifest`. O `firebase_core` tem o
mesmo comportamento sem o `google-services.json`. **Rode o app no aparelho antes
de commitar** — não confie no `flutter analyze`, que passa feliz nos dois casos.

### O que já existe e você não precisa criar
- `lib/core/telemetry/telemetry.dart` — interface, no-op, captura de erros
  (`FlutterError.onError` + `PlatformDispatcher.onError` + zona guardada).
- `lib/core/telemetry/eventos.dart` — os 10 eventos, amarrados aos 5 sinais de
  sucesso do [05 §7](05-ESCOPO-E-ROADMAP.md).
- `test/telemetry_test.dart` — **trava a regra de privacidade**. Se você
  adicionar evento com parâmetro que pareça dinheiro ou dado pessoal, ele falha.
  Isso é de propósito: leia o motivo antes de mexer.
- Opt-in já ligado em Configurações e aplicado **na hora** (LGPD).

### A regra que não se negocia
**Nenhum evento carrega dinheiro, nome, cliente ou texto digitado.** O app
promete no onboarding "sem enviar seus dados". Medir *que* a pessoa registrou
uma entrada é legítimo; medir *quanto* ela recebeu é quebrar a promessa.

---

## 3. Play Console

### Passo humano
- Criar o app na conta `4935491440305715031`.
- **Data Safety** e questionário **IARC**: só UI, não existe API.
- Declarar que o app **não coleta dados** por padrão (a telemetria é opt-in e
  não manda dado pessoal — releia §2 antes de preencher, e preencha honesto).

### Produto de assinatura
**Um só: R$ 6,90/mês.** Decisão do dono em 19/07 — ver
[05](05-ESCOPO-E-ROADMAP.md) e [08 §9.2](08-PLANO-OFICIAL.md).
A tela do Pro já mostra um plano único (`lib/features/pro/pro_screen.dart`).

### Billing real — **isto não existe ainda**
Hoje o Pro é **flag local**: `EntitlementRepository` grava um bool, e
`proProvider.grant()` libera sem cobrar nada. Dá pra virar Pro de graça.

Ao ligar o billing de verdade:
- `grant()` passa a ser chamado **só** no sucesso da compra verificada.
- Restaurar compra em aparelho novo precisa existir (senão vira ★1 de quem pagou).
- O texto provisório na tela do Pro (*"por ora o Pro é ativado localmente pra
  você testar"*) sai junto.

### Também pendente pra loja
- Política de privacidade em **URL pública** (o texto já existe dentro do app,
  em `lib/features/legal/legal_texts.dart`). O site é `4yu.com.br`, deploy por
  `website/scripts/deploy.py`.
- Ficha: título/descrição ASO — ver [01 §3](01-MAPA-DE-OPORTUNIDADES.md).
- Prints e ícone.
- Faixa de teste interno.

---

## 4. Contexto que evita retrabalho

- **O app está em reestruturação grande** (Fases 1–2 do
  [08](08-PLANO-OFICIAL.md)): `Perfil`→`Area`, `Projeto`→`Trabalho`,
  `ReservaEntry`→`Entrada`, e as abas viram **Início · Trabalhos ·
  Configurações**. Se você pegar o repo no meio disso, confira o `git log`.
  **A telemetria não é afetada** — os nomes de evento são estáveis de propósito.
- O app **não estava publicado** em 19/07, então não há usuários pra migrar.
- Versão nesse momento: `0.6.0+8`.

---

## 5. Checklist

**Humano**
- [ ] Criar projeto Firebase (deixar criar a própria propriedade GA4)
- [ ] Conceder `Firebase Admin` à SA `claude-automation@…`
- [ ] Criar o app na Play Console
- [ ] Data Safety + IARC
- [ ] Criar a assinatura de R$ 6,90/mês

**Agente**
- [ ] Registrar app Android no Firebase + baixar `google-services.json`
- [ ] `firebase_core` + `analytics` + `crashlytics` no pubspec e no gradle
- [ ] `TelemetryFirebase` + trocar a linha em `main.dart`
- [ ] **Rodar no aparelho** (o analyze não pega crash de boot)
- [ ] Billing real substituindo a flag local + restaurar compra
- [ ] Publicar a política de privacidade no site
- [ ] Ficha + prints + teste interno
