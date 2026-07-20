# 13 — Handoff: estado depois da sessão de Play, Firebase e billing

> Escrito em 20/07/2026, no fim de uma rodada longa que levou o app de "verde
> nos testes" pra **rodando no teste interno da Play, com billing real**. Para
> quem pega frio: leia este; ele substitui o [11](11-HANDOFF.md) como retrato do
> presente, e diz o que ainda falta (o gate de produção está no
> [12](12-CHECKLIST-PUBLICACAO.md), com os itens de infra já resolvidos aqui).

---

## 0. Onde as coisas estão

| | |
|---|---|
| Branch | `main` @ `f70f999` (tudo mergeado) |
| Versão | **`0.8.0+15`** |
| Testes | **288 passando**, `flutter analyze` limpo |
| **Teste interno da Play** | **bundle 15 no ar** (publicado via API) |
| App na Play | "**Quanto Cobro? Preço de Freela**" · package `com.fouryuapps.quantocobro` · **grátis** |
| Assinatura | **`pro_mensal` ACTIVE** (plano `mensal`) |
| Firebase | projeto `quanto-cobro`, GA4 própria (BRL) |

**Atualização 20/07 (sessão seguinte):**
- ✅ **App baixa e abre da Play** (teste interno) num aparelho real — o boot com
  Firebase de verdade está confirmado (a pessoa chegou até a tela de Pro).
- ✅ **Backup da keystore feito** fora da máquina (era a pendência crítica do §3).
- ✅ **Testadores** já na lista do teste interno.
- ✅ **Travessões removidos de todo o texto visível do app** (~40 strings): davam
  cara de "escrito por IA". A tela 3 do onboarding (consentimento) também foi
  encurtada. `analyze` limpo, 288 testes verdes. **Ainda não virou bundle novo** —
  precisa buildar/subir pra chegar no aparelho.
- ⚠️ **Compra de teste ainda dá "pagamento recusado":** é o §7.1 — falta cadastrar
  os e-mails em **Testes de licença**. Sem isso a Play tenta cobrança real, e não
  dá pra comprar do próprio app com a conta dona do Merchant (o "cartão de
  recebimento"). Com licença de teste, a compra vira um cartão de teste que sempre
  aprova, sem cobrar.

---

## 1. O que esta sessão fez

Do estado do [11](11-HANDOFF.md) (branch não mergeada, nada em aparelho) até aqui:

- **`build(android)`** — CI criado do zero (`.github/workflows/`: `ci`, `build-apk`, `build-aab`), assinatura de release, R8 ligado com regras de keep.
- **`fix(ux)`** — 3 achados do teste em aparelho: "Ver detalhamento" abria vazio (rota ignorava o `extra`); e-mail "teste" passava; números enormes no Resultado.
- **`feat(pro)`** — selo premium em roxo-marca (não ouro, que já é reserva — ver `core/theme/pro_colors.dart`).
- **`feat(fluxo)`** — amarra entrada↔trabalho: seletor reaproveitável, salvar no simulador, tirar salvar-proposta de trás do paywall, ligar entrada avulsa depois.
- **`feat(firebase)`** — telemetria no destino real (Analytics + Crashlytics).
- **`feat(onboarding)`** — consentimento de telemetria na última tela (opt-in honesto, LGPD).
- **`feat(billing)`** — Play Billing real contra `pro_mensal` + revogação no boot.

---

## 2. A automação da Play via API — o próximo agente PODE publicar sozinho

Descoberta desta rodada, e a que mais muda o trabalho: **a `play-sa` alcança
este app a nível de conta.** Com ela, o agente faz o ciclo inteiro sem o humano
tocar no console:

```
gh workflow run build-aab.yml           # CI builda o AAB assinado
gh run download <run> -D build/ci-aab    # baixa
# depois, via androidpublisher v3 (JWT da play-sa, escopo androidpublisher):
#   POST edits                           -> editId
#   POST /upload/.../edits/{id}/bundles?uploadType=media   (o .aab)  -> versionCode
#   PUT  edits/{id}/tracks/internal      {releases:[{status:completed, versionCodes:[vc]}]}
#   POST edits/{id}:commit
```

- SA: `claude-play@yu-automation` (`.secrets/play-sa.json`), escopo
  `https://www.googleapis.com/auth/androidpublisher`. JWT assinado com PyJWT
  (google-auth não está instalado; `pip` é bloqueado por PEP 668 — assine na mão).
- **O primeiro upload TEM que ser manual** (regra da Play). Já foi feito (o
  humano subiu o bundle 11 pela UI), então a partir daí a API sobe bundles novos.
- **Assinatura via API** (`monetization.subscriptions`): funciona, MAS exige o
  parâmetro **`regionsVersion.version=2022/01`** na criação — sem ele dá 400
  "Regions Version must be specified". Foi o gotcha que custou uma tentativa.
- Scripts desta sessão viveram no scratchpad (efêmero). Reconstruir é trivial
  com o passo a passo acima. **Não commitar script com o caminho da SA sem
  conferir a visibilidade do repo.**

---

## 3. Keystore e segredos desta sessão

- **Keystore de upload gerada:** `.secrets/quantocobro-upload.jks` (chmod 600),
  senha em `.secrets/4yu.env` como `QUANTOCOBRO_KEYSTORE_PASS`, alias `upload`.
  SHA-1 `55:A8:A6:62:23:38:6D:81:F4:F9:37:C5:71:65:79:EB:37:69:78:A4`.
- 4 secrets no GitHub (`KEYSTORE_BASE64`, `STORE_PASSWORD`, `KEY_PASSWORD`,
  `KEY_ALIAS`) — o `build-aab.yml` recria o `key.properties` a partir deles.
- ✅ **RESOLVIDO (20/07):** backup do `.jks` + da senha guardado **fora da
  máquina**. (Era: perder depois de publicar = nunca mais atualiza o app.)

---

## 4. Assinatura `pro_mensal` (criada e ativada via API)

- productId **`pro_mensal`** · base plan **`mensal`** · `P1M` · renovação
  automática · carência `P7D`.
- **Brasil: R$ 6,90** (regionalConfig BR). **Resto do mundo: USD/EUR 1,49**
  (`otherRegionsConfig` — cobre toda região não listada, todas as moedas).
- ⚠️ productId e basePlanId são **permanentes**. Preços são editáveis.

---

## 5. Firebase

- Projeto **`quanto-cobro`** (Spark/grátis), propriedade GA4 própria (moeda
  **BRL** — diferente do Deixei Aqui, que é USD por causa do AdMob; aqui não tem).
- **`android/app/google-services.json` versionado** (não é segredo, vai no APK).
- `firebase_core` + `analytics` + `crashlytics`; plugin gradle google-services +
  crashlytics (sobe o `mapping.txt` do R8 sozinho).
- `TelemetryFirebase` implementa a interface — nenhum call site mudou.
- **Opt-in de verdade:** desligado por padrão; ligado pelo consentimento na
  última tela do onboarding. `setHabilitado` desliga a coleta no lado nativo.
- `main.dart` é **defensivo**: se o Firebase falhar no boot, cai no no-op e o app
  sobe.

---

## 6. Billing — o modelo (pra NÃO reabrir a dúvida)

A dúvida que apareceu ("app offline + assinatura, como?") tem resposta e ela
está resolvida:

- **A conta que paga é a do Google no aparelho, não login no app.** A Play Store
  cobra, guarda o entitlement e sincroniza entre aparelhos da mesma conta. O app
  **não tem login, não tem backend, não faz chamada de rede** — só chama o
  Billing local. "Offline" e "cobrar assinatura" convivem: a Play é a ponte.
- **Assinar:** botão abre a compra da loja; o Pro só liga quando a loja
  **confirma** (`billing_service.dart` → `onEntitled` → `grant`). Fim do "Pro
  sem pagar" (antes era um bool local).
- **Cancelar:** `_sincronizar` no boot (e no "Restaurar compras") reconcilia com
  a loja. Revoga **só com checagem conclusiva** (loja disponível, restore sem
  erro). Offline/erro → não mexe, **nunca tranca quem pagou**.
- **Dívida consciente:** sem RTDN (notificações em tempo real da Play) +
  servidor. Isso daria revogação instantânea + anti-fraude, mas custa backend +
  identidade — e briga com a tese "offline, sem cadastro". Desnecessário pra v1;
  o `queryPurchases` no boot já reflete o estado real. Fica pra quando/se
  aparecer fraude ou reembolso em massa.
- Preço na tela vem da **loja** (moeda do usuário), não chumbado.

---

## 7. O que falta — o gate de PRODUÇÃO (nada é código travado)

O caminho crítico de **código acabou** (billing era o último). O resto é
console, loja e relógio.

### 7.1 Humano, pra TESTAR agora (minutos)
- [ ] **Testes de licença** (Play Console → Configurações → Testes de licença):
      adicionar os e-mails testadores. **CONFIRMADO como o bloqueio da compra:**
      sem isso a Play tenta cobrança real e recusa (não dá pra comprar do próprio
      app com a conta dona do Merchant). Cadastrado, a compra vira cartão de teste
      que sempre aprova, sem cobrar. Esperar uns minutos e re-logar no aparelho.
- [x] ~~Instalar pelo link do teste interno e confirmar que abre sem crashar~~
      — ✅ feito 20/07: baixa e abre da Play, `firebase_core` sobe no aparelho.

### 7.2 Humano, pra PUBLICAR (console/loja/jurídico)
- [ ] **Declarações do app** (destravam o serve/publicação): financeiro =
      **nenhum**; saúde = **não**; **Data Safety** (agora com Firebase
      Analytics/Crashlytics, opt-in); **IARC** (classificação etária);
      público-alvo.
- [ ] **Política de privacidade hospedada** numa URL pública + **revisão
      jurídica** (é rascunho; corrigir ≠ validar).
- [ ] **Ficha:** descrição curta/longa + **feature graphic 1024×500** (falta; o
      agente gera com o padrão de `test/ferramentas/`). Ícone 512 e 5 capturas já
      existem em `docs/screenshots/loja/`.
- [ ] **Teste fechado: 12 testadores × 14 dias** — o relógio de lançamento. Por
      app, teste interno não conta. A lista "4YU internos" reaproveita, mas hoje
      tem 3; precisa chegar a 12. **Começar cedo.**

---

## 8. Gotchas da máquina (mesmos do 11, revalidados)

- **WSL não builda** (derruba a máquina). O caminho é o CI — que agora existe.
- Segredos em `/home/gabrielbarbosa/dev/gabriel/4yu-apps/.secrets/` (chmod 700).
- Em casa o usuário é `gabfelix`; no trabalho `gabrielbarbosa`. Trocou de
  máquina, conserte os caminhos absolutos.
- Downloads que o Windows enxerga: `/mnt/c/Users/gabriel.barbosa/Downloads/`.
- Publicar no interno via API: o AAB tem que ter versionCode **maior** que o do
  bundle já no track.
