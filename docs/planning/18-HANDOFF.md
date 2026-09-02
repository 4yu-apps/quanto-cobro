# Handoff, plano 18 (v0.10.0), parado na Task 4 de 17 (0.10.0+21 no ar)

**Data:** 01/09/2026. **Branch:** `main`, empurrada pro GitHub em `d274a06`.
**Estado:** `flutter analyze` sem issue, `flutter test` 387 verdes, árvore limpa.
**0.10.0+21 publicada na Play** (tasks 1 a 4). O site segue sem publicar.

Este arquivo é pra você (ou pro próximo agente) retomar sem reler a conversa.
O plano em si continua sendo a fonte da verdade:
[18-PLANO-FLUXO-FOLGA-E-VISUAL.md](18-PLANO-FLUXO-FOLGA-E-VISUAL.md).

---

## O que já entrou (4 de 17)

| Task | Commit | O que mudou |
|---|---|---|
| 1 | `8c2286a` | Termos param de prometer "nunca terá anúncio"; Pro lista o que já entrega |
| 2 | `f9c930d` | Motor: `diasFolgaAno` explícito, `horasBrutasPorRotina`, fator 0,65 → 0,74 |
| 3 | `ff33ef2` + `db6d308` | Passo 2 da calculadora reescrito; `comTela` passa a honrar `textScale` |
| 4 | `43fb911` | Resultado: "faturados" vira "você precisa cobrar" |

O invariante do motor foi preservado e conferido duas vezes: `Area.padrao()`
(5 dias × 6 h, 30 de folga) continua dando **85 h**.

### Um commit do site esperando você

`git -C ../website log origin/main..HEAD` mostra **5 commits não empurrados**.
Só o mais novo é meu:

- `2594848` fix(quanto-cobro): política de privacidade espelha a nova cláusula de anúncios

Os outros 4 são seus, de antes. Não empurrei nem publiquei nada do site porque
não escrevi esses commits e não os revisei. Quando quiser: `git -C ../website
push`, e o deploy é `python3 ../website/scripts/deploy.py site`.

**Importante:** a política do app (`legal_texts.dart` §3) e a do site precisam
dizer a mesma coisa. Hoje dizem, mas só localmente. Enquanto o site não subir,
a versão pública ainda promete "não exibe anúncios", que é a promessa que a
Task 1 existiu pra apagar.

---

## Publicado: 0.10.0+21, direto na produção

Em 01/09/2026, `versionCode 21` foi **publicado direto na faixa de produção**,
sem passar por teste interno. Confirmado relendo a faixa numa edit nova (o
console dizer "publicado" não é evidência):

```
production -> releases[0]: name 0.10.0, versionCodes ["21"], status completed
```

O que está no ar contém **só as tasks 1 a 4**. As tasks 5 a 17 seguem pendentes,
então o passo 2 novo da calculadora foi pro usuário **sem** a tela de folga que
as tasks 9/10/11 criariam.

### Teste interno não é obrigatório

Ficou registrado errado na primeira versão deste handoff. O relógio de 12 × 14
dias corre no teste **fechado**, e essa conta já passou por ele (0.9.2 em
23/ago). O que a Play exige de verdade é só **versionCode maior que o
publicado**. O `promote-to-production.py` é que recusa versionCode fora de faixa
de teste, e isso é trava do script, não regra do Google.

Por isso nasceu o `scripts/upload-to-production.py`: build → upload → produção
num movimento, com dry-run por padrão, igual ao irmão.

```bash
export PATH="$HOME/fvm/versions/stable/bin:$PATH"
set -a && . ../.secrets/4yu.env && set +a
flutter build appbundle --release
python3 scripts/upload-to-production.py            # dry-run: sobe, valida, descarta
python3 scripts/upload-to-production.py --commit   # publica
```

O `validate` do dry-run é prova barata de duas coisas que não têm API de
leitura: o acesso à produção está concedido, e a faixa tem países selecionados.
Passou = estava tudo certo.

**Na próxima release, lembre de bumpar o `versionCode`.** O 21 já foi usado.

---

## O que falta: 13 tasks

A ordem importa: **1→…→9, depois 11, depois 10**, depois 12→17. A 11 vem antes
da 10 de propósito, e isso **não é estilo**: `Glossario.of` usa `_all[id]!`
([glossario.dart:129](../../lib/core/glossario/glossario.dart)), então a tela
de folga com um `HelpDot('folga')` sem o verbete **crasha**, não degrada.

### Trilha B, o que falta

| # | Task | Tamanho | O que é |
|---|---|---|---|
| 5 | Proposta: prazo + pagamento | Grande | Prazo em dias (úteis/corridos) e forma de pagamento por chips. Mexe no modelo e na tela |
| 6 | Trabalho: data de entrega | Médio | Campo opcional + "faltam N dias". Sem cronômetro, de propósito |
| 7 | Simulador: alerta de capacidade | Pequeno | Avisa quando o projeto pede mais hora do que o mês tem |
| 8 | Custos: "+" no título | Pequeno | Adicionar custo sem rolar |
| 9 | Motor: `computeFolga` | Médio | Só engine. Férias como decisão de preço |
| 11 | Glossário: 2 verbetes | Pequeno | `folga` e `horas_cobraveis`. **Antes da 10** |
| 10 | Tela do Simulador de folga | Grande | A tela nova (`/folga`), ouro em superfície grande |

### Trilha A (visual), o que falta

| # | Task | Tamanho | O que é |
|---|---|---|---|
| 12 | Botão "Recebi" na navbar | Médio | Círculo esmeralda, alcançável de qualquer aba |
| 13 | Nome + saudação | Médio | "Boa tarde, Gabriel". Mexe na privacidade de novo (app + site) |
| 14 | Anel no Teto do MEI | Médio | Barra vira anel com % no centro |
| 15 | Ações rápidas no Painel | Médio | Orçar · Folga · Histórico · Recalcular; "Recebi" sai do Painel |
| 16 | `Cena`, ilustração assinatura | Médio | Onboarding, vazio e folga |
| 17 | Release 0.10.0+21 | Pequeno | Bump, prints, ficha. **Para antes de publicar** |

As tasks 12 e 15 são um par: a 12 põe o "Recebi" na navbar e a 15 tira o do
Painel. Entre uma e outra os dois coexistem por um commit, e isso é aceitável
segundo o plano. Se você parar entre elas, o app fica com dois botões, feio mas
funcionando.

---

## Como retomar

O ledger com tudo (rulings, commits, achados) está em
`.superpowers/sdd/18-PLANO-FLUXO-FOLGA-E-VISUAL/progress.md`, fora do git.

Numa sessão nova, o pedido que funciona é o mesmo de antes:

> Execute o plano docs/planning/18-PLANO-FLUXO-FOLGA-E-VISUAL.md usando a skill
> superpowers:subagent-driven-development, retomando da Task 5. O ledger em
> .superpowers/sdd/18-PLANO-FLUXO-FOLGA-E-VISUAL/progress.md tem o que já foi
> feito. Não publique nada.

### Três coisas que o próximo agente precisa saber e o plano não diz

1. **`flutter` não está no PATH.** O SDK vive em `~/fvm/versions/stable/bin`
   (o `~/fvm/bin` só tem o launcher do fvm). Sem isso, todo subagente reporta
   um bloqueio falso de tooling:
   ```bash
   export PATH="$HOME/fvm/versions/stable/bin:$PATH"
   ```
2. **`kDiasFolgaPadrao` mora em `area.dart`, não no motor.** O plano manda pôr
   no `calc_engine.dart`, mas isso é ciclo de import (o motor já importa
   `area.dart` na linha 3). A decisão tomada: constante em `area.dart`,
   reexportada com `export '../model/area.dart' show kDiasFolgaPadrao;`. Quem
   importa o motor continua enxergando, então nada mais no plano muda.
3. **O trailer de commit do plano está velho.** Ele diz `Claude Fable 5.1`; use
   o do modelo que estiver rodando.

### Um problema achado no caminho, já resolvido

A revisão da Task 3 pegou algo que não estava no plano: `comTela`
([test/support/tela.dart](../../test/support/tela.dart)) aceitava um parâmetro
`textScale` e **nunca o aplicava**. O `teto_mei_card_test.dart` pedia 200% e
rodava em 100% havia tempo, e o passo 2 da calculadora não estava na matriz de
layout. Os dois foram corrigidos em `db6d308`, e agora a garantia de
acessibilidade do plano (320×640 com fonte 200%) é verificação de verdade, não
promessa. Vale saber porque **todas as tasks restantes se apoiam nesse mesmo
helper**.

---

## O que fica de fora, de propósito

O plano já decidiu e não convém reabrir sem motivo novo: cronômetro / registro
diário de horas (é Toggl), IA pra dúvida de imposto (quebra offline e erra
número fiscal), aba "Férias" (são três abas, sempre), e taxas bancárias na
proposta (não é informação pro cliente). O raciocínio completo está no
Apêndice B do plano.
