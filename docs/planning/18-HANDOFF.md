# Handoff, plano 18 (v0.11.0): fechado e publicado

**Data:** 02/09/2026. **Branch:** `main`.
**Estado:** `flutter analyze` sem issue, `flutter test` 457 verdes, árvore limpa.
**`0.11.0+22` está na produção da Play** desde 02/09/2026, com as 17 tasks.
Confirmado relendo a faixa numa edit nova:

```
production -> releases[0]: name 0.11.0, versionCodes ["22"], status completed
```

O plano continua sendo a fonte da verdade:
[18-PLANO-FLUXO-FOLGA-E-VISUAL.md](18-PLANO-FLUXO-FOLGA-E-VISUAL.md).

---

## As 17 tasks

Trilha B (fluxo, cálculo, modelo) e trilha A (visual) fechadas.

| Task | O que mudou |
|---|---|
| 1 | Termos param de prometer "nunca terá anúncio" |
| 2 | Motor: `diasFolgaAno` explícito, fator 0,65 → 0,74 |
| 3 | Passo 2 da calculadora reescrito; `comTela` passa a honrar `textScale` |
| 4 | Resultado: "faturados" vira "você precisa cobrar" |
| 5 | Proposta: prazo em dias (úteis/corridos) e pagamento por chips |
| 6 | Trabalho: data de entrega opcional, com "faltam N dias" |
| 7 | Simulador: aviso quando o projeto pede mais hora do que o mês tem |
| 8 | Custos: "+" ao lado do título |
| 9 | Motor: `computeFolga`, férias como decisão de preço |
| 10 | Tela do Simulador de folga (`/folga`) |
| 11 | Glossário: verbetes `folga` e `horas_cobraveis` |
| 12 | "Recebi" vira botão redondo colado na navbar |
| 13 | Nome opcional + saudação no Painel |
| 14 | Teto do MEI vira anel |
| 15 | Ações rápidas em círculo no Painel; "Recebi" sai de lá |
| 16 | `Cena`, a ilustração assinatura |
| 17 | Bump `0.11.0+22`, prints regenerados, nota "Novidades" na ficha |

As tasks 1 a 4 saíram numa sessão; 5 a 14 em outra; 15 a 17 em 02/09/2026.

---

## Como foi publicada (e a armadilha que quase passou)

O caminho:

```bash
export PATH="$HOME/fvm/versions/stable/bin:$PATH"
set -a && . ../.secrets/4yu.env && set +a
flutter build appbundle --release
python3 scripts/upload-to-production.py            # dry-run: sobe, valida, descarta
python3 scripts/upload-to-production.py --commit   # publica
```

Teste interno **não** é requisito: o relógio de 12 × 14 dias corre no teste
fechado, e essa conta já passou por ele (0.9.2, em 23/ago). O que a Play exige
é versionCode maior que o publicado — daí o **22**, já que o 21 foi usado.

Depois do commit, **releia a faixa numa edit nova**. Console dizer "publicado"
não é evidência.

### `set -a && . ../.secrets/4yu.env` NÃO é opcional no build

**Sem as variáveis carregadas, o `flutter build appbundle --release` assina com
a chave de DEBUG e não avisa.** O `build.gradle.kts` cai no
`signingConfigs.debug` quando não acha `key.properties` nem
`QUANTOCOBRO_KEYSTORE_{FILE,PASS}` / `QUANTOCOBRO_KEY_ALIAS` — é fallback
silencioso, o build responde "✓ Built" igual.

Aconteceu nesta sessão: o primeiro AAB saiu com `CN=Android Debug`. Confira
sempre antes de subir:

```bash
AAB=build/app/outputs/bundle/release/app-release.aab
CERT=$(unzip -l "$AAB" | grep -oE "META-INF/[A-Z0-9]+\.(RSA|EC|DSA)" | head -1)
unzip -p "$AAB" "$CERT" | keytool -printcert | grep -E "Owner|SHA256:"
```

Tem que dizer `CN=4YU Apps` e o SHA256
`C4:4D:A9:73:...:63`. Se disser `CN=Android Debug`, o env não estava carregado.

### A ficha da loja: falta você

`docs/planning/14-FICHA-LOJA.md` tem a seção **Novidades (0.11.0)**, 494 de 500
caracteres — e é o mesmo texto que o `upload-to-production.py` mandou pela API,
então as notas da release **já estão no ar**. Se editar uma, edite a outra.

O que **não** tem API e continua sendo seu: **trocar as capturas** na ficha. As
novas estão em `docs/screenshots/loja/` e já mostram o Painel de hoje (anel,
quatro ações, "Recebi" na navbar). As que estão na Play ainda são as antigas.

### O site: quitado

A política do site foi atualizada e **está no ar**. Conferido em 02/09/2026
buscando o HTML servido, não o git:

```bash
curl -s https://4yu.com.br/quanto-cobro/privacidade/ | grep -oE "<h3>3\.[^<]*</h3>"
# -> <h3>3. Anúncios</h3>
```

O item 3 deixou de se chamar "Este app não exibe anúncios" e agora diz que a
versão gratuita **pode passar a exibir anúncios**, com a promessa de atualizar
a política antes e de o Pro seguir sem. É a mesma redação do
`legal_texts.dart` §3: app e site dizem a mesma coisa, que era o ponto.

Não há commit pendente em `../website` (commit `2594848`, já empurrado).

---

## O que o próximo agente precisa saber e o plano não diz

1. **`flutter` não está no PATH.** O SDK vive em `~/fvm/versions/stable/bin`
   (o `~/fvm/bin` só tem o launcher do fvm):
   ```bash
   export PATH="$HOME/fvm/versions/stable/bin:$PATH"
   ```
2. **`kDiasFolgaPadrao` mora em `area.dart`, não no motor** — pôr no
   `calc_engine.dart`, como o plano manda, é ciclo de import.
3. **`find.bySemanticsLabel` acha zero sem `tester.ensureSemantics()`.** Sem um
   `SemanticsHandle` ligado, a árvore de semântica não existe, e o finder falha
   como se o widget não estivesse na tela. Pra achar o "Recebi" da navbar num
   teste que não liga semântica, use `find.byTooltip('Recebi um pagamento')` —
   funciona na barra e no trilho, onde `find.text('Recebi')` só funciona na
   barra (no trilho o botão é só o círculo, sem rótulo).
4. **Teste que não fixa `Tela` roda em 800×600**, que é `medium`: trilho
   lateral, não barra de baixo. Foi o que quebrou três casos do
   `entrada_fluxo_test.dart` na Task 15.
5. **A tela de folga é uma `ListView`**, e o cartão da resposta mora abaixo da
   dobra em 320×640. Teste que procura "SUA HORA PRECISA SER" precisa rolar
   antes — e com `scrollable:` explícito, senão o `Scrollable` do campo de
   dinheiro faz o helper achar dois e morrer com "Too many elements".

---

## O que fica de fora, de propósito

O plano já decidiu: cronômetro / registro diário de horas (é Toggl), IA pra
dúvida de imposto (quebra offline e erra número fiscal), aba "Férias" (são três
abas, sempre), e taxas bancárias na proposta (não é informação pro cliente). O
raciocínio completo está no Apêndice B do plano.
