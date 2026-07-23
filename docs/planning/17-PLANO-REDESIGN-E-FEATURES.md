# 17 — Plano de execução: redesign + features (o mapa sem surpresa)

> **O que é:** o plano de obra de tudo que a nossa conversa gerou — o redesign
> (doutrina de contenção) **mais** as features (USD, regime avançado, teto MEI,
> Fator R, lembrete). Diz **quais telas mudam, o que muda em cada uma, o que muda
> de cálculo, de modelo, de plugin, e em que ordem** — pra não ter susto.
>
> **Bases:** [15](15-FLUXO-USD-E-REGIME-AVANCADO.md) · [16](16-SITEMAP-E-JORNADA-POR-REGIME.md)
> · [Doutrina](../design-build/DOUTRINA-DE-CONTENCAO.md) · mock aprovado
> (`docs/design-reference/mock-hierarquia.html`).

---

## 1. Duas trilhas, separáveis de propósito

| Trilha | O que é | Risco | Toca cálculo? | Toca plugin? |
|---|---|---|---|---|
| **A — Redesign** | aplicar a doutrina (hierarquia, glow racionado, número solto, variedade) nas telas que já existem | **baixo** (visual) | não | não |
| **B — Features** | USD, regime avançado, teto MEI, Fator R, lembrete | médio | **sim** | sim (lembrete, fx) |

**Regra:** trilhas em commits separados. Redesign não espera feature e vice-versa.
Se o redesign quebrar algo, reverte visual sem perder cálculo — e o contrário.

---

## 2. Telas que mudam (o inventário do impacto)

| Tela / arquivo | Redesign (A) | Feature (B) | Testes a rever |
|---|---|---|---|
| **Painel** `painel_screen.dart` | herói número-solto · glow 1/tela · ações planas · gráfico mensal (some se vazio) · Divisão com R$ · anel | cartão de **teto MEI** (só se regime=MEI) | `painel_smoke` `layout_matrix` `overflow` `tablet` |
| **Reserva** `entrada_screen.dart` | herói solto · Divisão com R$ | **USD**: link "outra moeda" → fx · **fix fluxo: salvar→sai** (tira "registrar outro") | `entrada_fluxo` `entrada_a11y` |
| **Meus Trabalhos** `trabalhos_screen.dart` | 1 destaque + linhas planas com inicial colorida | mostra moeda de origem (USD) na linha | `trabalho_test` `vinculo_trabalho` |
| **Detalhamento** `detalhe_screen.dart` | herói + linhas planas | **furar a linha de imposto** → bottom sheet (faixa/INSS/dedução) · **alíquota efetiva** visível | — |
| **Resultado** `resultado_screen.dart` | herói + Divisão com R$ | alíquota efetiva visível | `overflow` `layout_matrix` |
| **Simulador** `simulador_screen.dart` | herói + Divisão com R$ | — | `simulador_salvar` |
| **Calculadora** `calc_screen.dart` | passos limpos (já é 1-pergunta/tela) | **Fator R**: se regime=Simples, pergunta a mais (pró-labore) | — |
| **Ajustes** `config_screen.dart` | linhas planas | toggle do **lembrete** · **versão do app** no rodapé | `config_font` |

> **Guardrail:** os testes de layout (`layout_matrix`, `overflow`, `tablet`) vão
> precisar de ajuste quando a estrutura da Painel/Resultado mudar. **É esperado, não
> é regressão** — cada fase reescreve o teste da tela que tocou, e a suíte fica
> verde antes do commit.

---

## 3. Mudanças de CÁLCULO (o que o motor ganha)

1. **Anexo V + Fator R** (`tax_tables.dart` + `calc_engine.dart`):
   - Adicionar `kFaixasSimplesAnexo5` (3 primeiras faixas).
   - `fatorR = folha12m / receita12m`; ≥0,28 → Anexo III, <0,28 → Anexo V.
   - `aliquotaEfetivaSimples` passa a receber a folha/pró-labore e escolher o anexo.
   - **Corrige a subestimação atual** (hoje assume sempre Anexo III/barato).
2. **USD → reserva** (`fx_service.dart` já existe; ligar):
   - Converter USD→BRL (PTAX D-1, fallback open.er-api) **antes** de aplicar o
     regime. O imposto roda sobre o valor **em reais** (o motor não muda).
3. **Teto MEI** (agregação nova, dado já existe):
   - Somar `Entrada.valor` do ano corrente → comparar com `kTetoAnualMei` (81k) e o
     limite de 20% (97,2k). Três zonas. Projeção linear simples (ritmo × meses
     restantes) pra estimar quando encosta.
4. **Alíquota efetiva exposta** (`aliquotaEfetiva` já existe): só passa a ser
   **mostrada** — no herói (subtítulo) e no detalhamento. Zero cálculo novo.

> Nada disso muda o gross-up nem o `computeReserva`/`computeValorHora` existentes —
> são adições ao lado, com teste próprio. A suíte de cálculo (`calc_engine_test`,
> `moeda_test`, `fx_test`) ganha casos, não reescreve.

---

## 4. Modelo & persistência

- **`Entrada`** ganha `moedaOrigem` (String?, ex. "USD") e `taxa` (double?) — pra
  rastrear o câmbio usado. `valor` continua em BRL (o comentário do modelo já dizia
  "já em reais, convertido"). Migração: campos nuláveis, retrocompatível.
- **Agregação anual** (teto MEI): query no histórico de `Entrada` por ano. Sem
  tabela nova — é `where(year==atual).sum(valor)`.

---

## 5. Plugins / dependências (o que entra, e quando)

| Dep | Pra quê | Fase | Cuidado |
|---|---|---|---|
| `flutter_local_notifications` + `timezone` | lembrete DAS/carnê-leão | F7 | permissão POST_NOTIFICATIONS (And.13+); **alarme inexato** (sem exact-alarm/risco Play); reagendar no boot; init timezone America/Sao_Paulo |
| `package_info_plus` | mostrar versão no Ajustes (0.8.1+17) | F1 | trivial, sem permissão |
| `http` (já existe) | fx | F3 | + endpoint **BCB PTAX** (olinda.bcb.gov.br) com fallback open.er-api |

> **Lição do repo:** plugin nativo já derrubou o boot uma vez (AdMob). Cada plugin
> novo entra atrás de try/catch defensivo no init, como o Firebase — nunca crasha o
> boot por config ausente.

---

## 6. Mudanças de FLUXO / navegação

- **Reserva salvar → SAI** pra Meus Trabalhos (ou Painel) com feedback. Remove o
  "registrar outro". (fix apontado pelo Gabriel.)
- **USD é estado da Entrada** (link "recebi em outra moeda"), não rota nova. Default
  esperto: onboarding "exterior" pré-seleciona dólar.
- **Detalhamento vira drill**: tocar a linha de imposto (ou a Divisão) → **bottom
  sheet**. Não é tela nova.
- **Teto MEI = cartão no Painel** (só regime MEI). Não é destino novo.
- **Lembrete = toggle em Ajustes** + notificação de sistema. Frente própria.

O hub (Painel) **não ganha aba nem destino novo.** Tudo é profundidade nos nós que
já existem — coerente com "fluxo linear e imaginável".

---

## 7. Sequência de fases (ordem de obra)

| Fase | Entrega | Trilha | Risco |
|---|---|---|---|
| **F1** | **Painel redesenhada** (doutrina) + versão no Ajustes | A | baixo |
| **F2** | Reserva (redesign + fix salvar→sai) + Meus Trabalhos (redesign) | A+B | baixo |
| **F3** | **USD na Entrada** (fx ligado, PTAX+fallback, moedaOrigem/taxa) | B | médio |
| **F4** | Detalhamento bottom sheet + alíquota efetiva visível (Resultado/Reserva/Painel) | A+B | baixo |
| **F5** | **Teto MEI** (agregação anual, 3 zonas, projeção Pro) | B | médio |
| **F6** | **Fator R / Anexo V** (calc + pergunta no fluxo Simples) + **revisar/retestar** cálculo | B | médio |
| **F7** | **Lembrete** (plugin, permissão, agendamento inexato, boot) — frente própria | B | médio |

Cada fase: **analyze limpo + suíte verde + commit próprio**. Nada de fase que
deixa o app quebrado no meio.

---

## 8. Riscos & guardrails (o que pode surpreender, e o antídoto)

- **Testes de layout vão mudar** — esperado; reescrevo o da tela tocada na mesma fase.
- **"Não mexer no DS"** — a doutrina é *uso*, não troca token/paleta/fonte. Se eu
  precisar de uma cor/token novo, **paro e pergunto** antes.
- **PTAX pode falhar/estar fora do ar** — fallback open.er-api + selo "estimativa".
- **Permissão de notificação negada** — degradar com elegância (o cartão in-app de
  vencimento continua; só não chega push).
- **Reversível:** cada fase é commit isolado; se não curtir o visual de uma tela,
  reverte aquela sem tocar no resto.

---

## 9. Definição de pronto (por fase)
- `flutter analyze` sem issue.
- `flutter test` verde (com os testes da tela atualizados).
- Sem plugin que crashe boot (init defensivo).
- Commit próprio, mensagem clara, push.
- Redesign: bate com o mock aprovado e obedece as 6 leis da doutrina.

---

*Início: F1 — portar a Painel do mock pro Flutter, dentro da doutrina, sem tocar no
DS. Depois na ordem acima. As telas novas (USD/teto/detalhamento) nascem já na lei.*
