# 12 — Checklist até a publicação oficial

> Escrito em 20/07/2026. Estado do código: `main` em `0.8.0+11`, 283 testes
> verdes, CI + build de APK funcionando, R8 ligado. Este doc é **só o que falta**
> até o app estar publicado na Play. Marca o que já foi e o que trava o quê.
>
> Legenda: ✅ feito · ⏳ dá pra fazer agora · 🔒 bloqueado por um passo humano ·
> ⚠️ irreversível (erra e não desfaz).

---

## 0. O que já está pronto (não refazer)

- ✅ Branch de a11y/tablet mergeada, versão `0.8.0+11`.
- ✅ CI (`.github/workflows/`): analyze + testes + build de APK/AAB.
- ✅ Assinatura de release lê `key.properties`; R8 ligado com regras de keep.
- ✅ Telemetria escrita e opt-in (desligada por padrão) — falta só o destino.
- ✅ Ícone adaptativo (todas as densidades) + `icone-play-512.png`.
- ✅ 5 capturas da ficha em `docs/screenshots/loja/`.
- ✅ Fluxo de vínculo (entrada↔trabalho), Pro premium, três bugs do teste.

---

## 1. Código que precisa entrar

### 1.1 🔒⚠️ Play Billing — o único bloqueio REAL de lançamento
Hoje `core/billing/entitlement.dart` é um `bool` em `SharedPreferences`: **dá pra
virar Pro sem pagar**. `in_app_purchase` nem está no `pubspec.yaml`.

- [ ] Adicionar `in_app_purchase` ao `pubspec.yaml`.
- [ ] Serviço de compra: `queryPurchases` no boot, restaurar, tratar renovação
      falha e período de graça. **É assinatura mensal, não compra única** — o
      playbook da casa fala em vitalícia porque foi escrito pro Deixei Aqui;
      aqui não vale (ver [08 §9.2](08-PLANO-OFICIAL.md), [11 §2.2a](11-HANDOFF.md)).
- [ ] Ligar no `EntitlementRepository`: o `grant()` local vira "a loja
      confirmou". O `ProNotifier` já existe; nenhum call site do app muda.
- [ ] Trocar o botão "Assinar" (hoje `grant()` local) pela compra real.

> ~90% dá pra escrever ANTES do passo humano, mas fica **intestável** até a
> assinatura existir no console: o ID do produto é irreversível e tem que bater.
> Depende de **2.3**.

### 1.2 🔒 Firebase — telemetria e crash
A camada existe e os eventos já disparam; falta o destino.

- [ ] `firebase_core` + `firebase_analytics` + `firebase_crashlytics` no pubspec.
- [ ] Versionar o `google-services.json` (⚠️ **não** é segredo, vai no APK; o
      `.gitignore` já foi liberado pra ele) — sai do passo **2.2**.
- [ ] Trocar UMA linha no `main.dart` (a instância `telemetry`). Nenhum call
      site muda.
- [ ] Regra de keep do Crashlytics no `proguard-rules.pro` (o bloco já está
      comentado lá, só descomentar quando entrar).

> ⚠️ Sem o `google-services.json`, `firebase_core` não sobe e o app **morre no
> boot**. Testar no aparelho logo depois de ligar.

### 1.3 ⏳ Conformidade técnica da Play
- [ ] Confirmar `targetSdk ≥ 35` (Android 15) — exigência da Play pra apps novos
      em 2026. Hoje usa `flutter.targetSdkVersion`; conferir o valor efetivo.
- [ ] Subir a versão de novo antes do AAB oficial (promover de `+11`).

---

## 2. Setup humano em console (o que nenhuma API faz)

### 2.1 ⚠️ Keystore de upload — o mais irreversível de todos
Perder depois de publicar = **nunca mais atualizar o app**.

- [ ] Gerar (uma vez) e guardar backup fora da máquina:
      `keytool -genkey -v -keystore ~/.android-keystores/quantocobro-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Secrets no GitHub (Settings → Secrets → Actions): `KEYSTORE_BASE64`
      (`base64 -w0` do .jks), `STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`.
- [ ] Rodar `build-aab.yml` (ele falha de propósito enquanto os secrets não
      existem, e confere no fim se não saiu com chave de debug).

> Isto é chave de **upload**; a Play re-assina com a dela (Play App Signing).

### 2.2 🔒 Firebase (destrava **1.2**)
- [ ] Criar o projeto Firebase, **deixando ele criar a própria propriedade GA4**
      (não apontar pra "4YU" — ver [CLAUDE.md](../../../CLAUDE.md)).
- [ ] GCP → IAM → `Firebase Admin` pra
      `claude-automation@yu-automation.iam.gserviceaccount.com`.
- [ ] Registrar o app Android (`com.fouryuapps.quantocobro`) e baixar o
      `google-services.json`.

### 2.3 🔒⚠️ Play Console — criar o app e a assinatura (destrava **1.1**)
- [ ] Criar o app na Play Console (package `com.fouryuapps.quantocobro`).
- [ ] Criar a **assinatura mensal R$ 6,90** — ⚠️ o ID do produto é
      **irreversível** e tem que bater com o código do billing.
- [ ] Cadastrar testador de licença (pra testar a compra sem pagar de verdade).

---

## 3. Ficha da Play e conformidade

- [ ] **Política de privacidade hospedada** numa URL pública (a Play exige o
      link). Hoje ela existe como rascunho (LegalScreen no app); precisa ir pro
      site e passar por olhada jurídica — ver **4**.
- [ ] **Data Safety** — declarar só o que Firebase Analytics + Crashlytics
      coletam, com o detalhe a favor: telemetria é **opt-in, desligada por
      padrão**. Fica bem mais enxuto que o do Deixei Aqui (sem mapa, sem
      anúncio, sem câmera — única permissão é `INTERNET`, pela cotação de câmbio).
- [ ] **IARC** — questionário de classificação etária (só UI).
- [ ] **Ficha da loja**: título, descrição curta e longa.
- [ ] Assets: ✅ ícone 512 · ✅ 5 capturas · [ ] **feature graphic 1024×500
      FALTA** (não está em `docs/screenshots/loja/`; gerar com o padrão de
      `test/ferramentas/`).
- [ ] Declaração de permissões: só `INTERNET` — justificar (câmbio).

---

## 4. Legal

- [ ] **Revisão jurídica da política de privacidade.** Ela foi *corrigida* nesta
      rodada (declarava AdMob depois de o anúncio ter saído), mas **corrigir ≠
      validar** — segue marcada como rascunho. Precisa de olhada jurídica antes
      da ficha.

---

## 5. Portão de teste (o pêndulo mais longo — 14 dias)

- [ ] **Teste fechado: 12 testadores × 14 dias.** ⚠️ É **por APP**, não por
      conta — as mesmas pessoas servem, mas entram na faixa DESTE app e o relógio
      zera. **Teste interno NÃO conta**; tem que ser fechado. Começar cedo: são
      14 dias corridos que travam a publicação.

---

## 6. Verificar no aparelho (a lacuna que teste não fecha)

- [ ] Rodar o AAB/APK de release num aparelho e percorrer:
      **compartilhar a proposta em PDF** (o `share_plus` é o que o R8 alcança),
      trilho/mestre-detalhe em tablet, ícone no lançador, e — depois do Firebase
      — que o app **sobe** e o evento chega na propriedade GA4 **do app**, nunca
      a do site.
- [ ] Provar fora do console: `curl`/telemetria no ar, não só "publicado" na tela.

---

## 7. Publicar — a ordem

1. **2.1** keystore + secrets  →  **2.2** Firebase  →  **2.3** Play + assinatura.
2. **1.2** Firebase no código  →  **1.1** billing contra o produto real.
3. Verificar no aparelho (**6**) com o AAB assinado de verdade.
4. **3** ficha + Data Safety + IARC + **4** política validada.
5. **5** subir no teste fechado e **esperar os 14 dias**.
6. Promover pra produção.

**Caminho crítico:** billing (1.1) e os 14 dias do teste fechado (5). O resto
corre em paralelo. Nada disso é código travado — é console, loja e relógio.
