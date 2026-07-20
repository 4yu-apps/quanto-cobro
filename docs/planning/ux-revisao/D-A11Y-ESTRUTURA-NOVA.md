# D — Acessibilidade da estrutura nova

> Auditoria de a11y das telas que nasceram em 19/07/2026 (Entrada, Trabalhos,
> Trabalho detalhe, Trabalho form, Painel, Histórico, Áreas, Marca, Calc 4
> passos). Base: WCAG 2.2 AA, TalkBack (Android é a plataforma que vai à loja),
> VoiceOver e Switch Access.
>
> **Não é achismo.** Rodei três sondas de semântica e uma de tipografia contra o
> app real (`flutter test`, Flutter 3.44.6) e apaguei os arquivos depois. Onde
> escrevo "confirmado", é saída de teste, não leitura de código. Onde é leitura,
> escrevo "leitura".
>
> **Eu proponho; a implementação é sua.** Código abaixo é pra colar e ajustar,
> não pra aplicar no escuro.

---

## 0. A leitura, em uma frase

O app tem um padrão de acessibilidade **certo e consistente** — um rótulo que
conta a história inteira, `ExcludeSemantics` embaixo pra ninguém ouvir duas
vezes. Ele é bom o bastante pra ser a regra da casa.

O problema é que, em cinco lugares, **o rótulo apaga mais do que ele conta**.
`ExcludeSemantics` sobre um bloco cujo `label` não menciona metade do conteúdo;
`semanticLabel: ''` num número que ninguém mais diz. O padrão está certo. A
disciplina que ele exige — *o rótulo tem que CONTER tudo que ele apaga* — é que
não está travada em lugar nenhum.

E há dois furos que não são de rótulo, são de **ação**: em duas telas, o alvo
que o leitor de tela enxerga não carrega a ação que ele promete. Esses são os P0.

---

## 1. P0 — bloqueia uso por pessoa com deficiência

### P0-1 · `areas_screen.dart:125` — o `MergeSemantics` engole o menu "Opções"

**O problema.** `_tile` envolve o `ListTile` inteiro num `MergeSemantics`. O
`ListTile` tem `onTap` (ativar a área) e o `trailing` tem um `PopupMenuButton`
(Editar cálculo · Renomear · Apagar). Os dois viram **um nó só**.

Confirmado por sonda:

```
id=4 merged=false mergeAll=true  label="Design | Toque pra ativar | R$ 92/h" tap=true
  id=5 merged=true              label="Design | Toque pra ativar | R$ 92/h" tap=true
    id=6 merged=true            label=""                                    tap=true
```

O nó `id=6` é o `PopupMenuButton`: `isMergedIntoParent = true` → **não é enviado
pra plataforma**. E o `performAction(tap)` no nó fundido caiu no `onTap` do
tile (`tileTocado=true, menuAberto=false`). É o comportamento documentado do
próprio SDK:

> *"If multiple nodes in the merged subtree can handle semantic gestures, the
> first one in tree order will be the one to receive the callbacks."*
> — `flutter/src/widgets/basic.dart:8085`

**Quem trava.** Qualquer pessoa com TalkBack/VoiceOver **não consegue renomear,
editar nem apagar uma área**. A palavra "Opções" nunca é falada — ela não está
nem no rótulo fundido. A pessoa não descobre que o menu existe, e se descobrisse
não conseguiria abrir. Ironia amarga: quando a área **já está ativa**,
`onTap: null`, o conflito some e o menu funciona. Ou seja, funciona só na área
que ela menos precisa mexer.

**A correção.** Tirar o `MergeSemantics`. O `ListTile` já funde título +
subtítulo sozinho; o merge só existia pra juntar o `R$ 92/h`, e isso se resolve
no rótulo.

```dart
// areas_screen.dart:125 — sem MergeSemantics: o menu volta a ser alvo próprio.
return Semantics(
  selected: ativa,
  child: ListTile(
    leading: Icon(
      ativa ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      color: ativa ? theme.colorScheme.primary : theme.colorScheme.outline,
    ),
    title: Text(a.nome),
    subtitle: Text(ativa ? 'Ativa' : 'Toque pra ativar'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${moneyBRL(vh)}/h',
          // "/h" é lido como "barra agá". Em fala, "por hora".
          semanticsLabel: '${moneyBRL(vh)} por hora',
          style: theme.textTheme.labelLarge?.copyWith(
            fontFeatures: AppType.tnum,
            color: theme.colorScheme.primary,
          ),
        ),
        PopupMenuButton<String>(
          // "Opções" sozinho, numa lista de três áreas, não diz opções DE QUÊ.
          tooltip: 'Opções de ${a.nome}',
          onSelected: (String op) async { /* … igual … */ },
          itemBuilder: (BuildContext c) => /* … igual … */,
        ),
      ],
    ),
    onTap: ativa ? null : () { /* … igual … */ },
  ),
);
```

**Varredura do mesmo padrão no resto do app:** o único outro `MergeSemantics`
com dois gestos dentro seria `calc_screen.dart:866` — checado, tem só um
`InkWell`, está seguro. `pro_screen.dart:253`, `historico_screen.dart:161/202`
e `trabalho_detalhe_screen.dart:303` também não têm ação dentro. **É só este.**

---

### P0-2 · O `Semantics(button:) + ExcludeSemantics(InkWell)` não tem ação de toque

**Onde.** É o padrão-assinatura dos cards clicáveis do app, em quatro lugares:

| arquivo:linha | o que é |
|---|---|
| `trabalhos_screen.dart:170` | o card do trabalho — **a lista inteira da aba Trabalhos** |
| `painel_screen.dart:285` | `_CardDoMes` — a porta do Histórico |
| `core/ui/tool_action_card.dart:35` | "Recebi um pagamento" e "Vou orçar um projeto" |
| `core/ui/hero_value_card.dart:55` | o chip da área no herói |

**O problema.** `ExcludeSemantics` apaga a semântica do `InkWell` — inclusive a
`SemanticsAction.tap`. Sobra um nó com `isButton: true` e **nenhuma ação**.
Confirmado por sonda, com o card do trabalho literal:

```
label="Augusto. Recebido 400 reais." tap=false hint="" button=true
```

Duas consequências, uma delas silenciosa:

1. **O `onTapHint: 'abrir o trabalho'` (linha 173) é código morto.** Repare no
   `hint=""` acima. O `onTapHint` do Flutter é um *hint override* que só é
   aplicado se o nó tiver a ação correspondente. Sem `tap`, ele evapora. A frase
   que você escreveu pra guiar a pessoa nunca foi falada, nem uma vez.
2. **Switch Access não alcança o card.** A ponte Android do Flutter deriva
   `AccessibilityNodeInfo.setClickable()` de `hasAction(TAP)`. Sem a ação, o
   varredor do Switch Access não oferece o item — a pessoa com deficiência
   motora **não abre nenhum trabalho, nem o card do mês, nem os dois botões
   protagonistas do Início**. Mesma coisa no VoiceOver (iOS), cujo
   `accessibilityActivate` depende da ação.

No TalkBack puro isso **funciona por acidente**: quando o nó não é clicável, o
TalkBack dispara um toque bruto no centro. Por isso ninguém percebeu. Mas é
acidente, e ele não cobre Switch Access nem iOS.

**A correção.** Passar a ação pro nó que a anuncia:

```dart
// trabalhos_screen.dart:170
return Semantics(
  button: true,
  label: _semantica(),
  onTapHint: 'abrir o trabalho',
  // Sem isto o nó é um botão que não sabe ser apertado — e o onTapHint acima
  // é descartado em silêncio pelo framework.
  onTap: () => context.push(Routes.trabalhoDetalhe, extra: trabalho.id),
  child: ExcludeSemantics(child: /* … igual … */),
);
```

E, pra isso não voltar a acontecer, um só lugar (é o mesmo espírito do
`announce()` centralizado em `a11y.dart`):

```dart
// core/ui/a11y.dart
/// Card pintado à mão que se comporta como BOTÃO no leitor de tela.
///
/// O par `Semantics(button:) + ExcludeSemantics` é o padrão da casa — e tem uma
/// armadilha: o Exclude apaga a `SemanticsAction.tap` do InkWell lá dentro.
/// Sobra um botão que o TalkBack lê e o Switch Access não alcança. Aqui a ação
/// é obrigatória por assinatura.
class SemanticButton extends StatelessWidget {
  const SemanticButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.tapHint,
    this.selected,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final String? tapHint;
  final bool? selected;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTapHint: tapHint,
    selected: selected,
    onTap: onTap,
    child: ExcludeSemantics(child: child),
  );
}
```

Aplicado nos quatro sites. `hero_value_card.dart:58` ganha um bônus na troca —
ver P1-9.

---

### P0-3 · `calc_screen.dart:871` — o passo 4 estoura assert em debug

Achado fora do meu escopo, mas caiu na sonda e não dá pra guardar:

```
'package:flutter/src/material/material.dart': Failed assertion: line 209 pos 15:
'!(shape != null && borderRadius != null)': is not true.
```

`_regimeOption` passa `borderRadius:` **e** `shape:` pro mesmo `Material` quando
`selected == true` — e um regime está sempre selecionado (`RegimeId.mei` é o
default). Ou seja: **o passo 4 da calculadora crasha em debug, sempre.** Em
release o assert é removido e a tela renderiza, então usuário não vê; mas
qualquer widget test que chegue no passo 4 morre, e é por isso que nenhum
existe.

```dart
// calc_screen.dart:871 — um só: o shape carrega o raio E a borda.
child: Material(
  color: selected
      ? theme.colorScheme.primaryContainer
      : theme.colorScheme.surfaceContainerLow,
  shape: RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(Radii.md),
    side: selected
        ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
        : BorderSide.none,
  ),
  child: InkWell(/* … igual … */),
),
```

---

## 2. P1 — degrada muito

### P1-1 · `entrada_screen.dart:134` — a fala antiga chega DEPOIS do "Guardado"

`_anunciar()` (linha 120) agenda um `Timer` de 900ms com *"Separe R$ 68 pro
imposto. Sobra R$ 332."*. `_salvar` (134) e `_desfazer` (107) **não cancelam
esse timer**. Digite o valor, toque em Guardar dentro de 900ms, e a sequência é:

> "Guardado. R$ 68 separados… Você já tem R$ 412 separados este mês."
> *…300ms depois…*
> "Separe R$ 68 pro imposto. Sobra R$ 332."

Pra quem não vê a tela, a segunda frase **desfaz a primeira**: soa como se o
salvamento não tivesse pegado e o app estivesse pedindo de novo. No caminho de
ouro, no gesto que se repete toda semana.

```dart
Future<void> _salvar(ReservaResult res, RegimeId regime, Area? area) async {
  // A fala do "digitando" não pode chegar depois da fala do "guardado".
  _announceTimer?.cancel();
  if (_salvando) return; // ver P1-2
  _salvando = true;
  Haptics.commit();
  // … igual …
}

void _desfazer() {
  _announceTimer?.cancel();
  final Entrada? e = _ultima;
  // … igual …
}
```

### P1-2 · `entrada_screen.dart:134` — `_salvar` é async e não tem trava

Nada impede dois disparos durante o `await entradasN.add(entrada)`: saem duas
entradas e o `Desfazer` só remove uma. Toque duplo é o normal de quem tem tremor,
usa Switch Access, ou de quem o TalkBack fez disparar duas vezes. Trava com o
`bool _salvando` do trecho acima, liberado no fim (`_salvando = false` junto do
`setState`).

### P1-3 · `_CofreDoMes` — `semanticLabel: ''` apaga o acúmulo *(resposta longa em §4.2)*

`entrada_screen.dart:525`. Ver §4.2. Correção:

```dart
MoneyCountUp(
  total,
  from: antes,
  duration: Motion.emphasized,
  curve: MotionCurves.landing,
  style: /* … igual … */,
  semanticLabel: 'No cofre este mês: ${moneyBRL(total)}',
),
```

### P1-4 · `_PreviaValorHora` — `semanticLabel: ''` esconde o número vivo *(§4.3)*

`calc_screen.dart:1006`. Ver §4.3. Correção (junto com o estouro de fonte, P1-8):

```dart
// calc_screen.dart:979 — uma parada só, e o número existe pra quem não vê.
return Padding(
  padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, 0),
  child: Semantics(
    container: true,
    label: 'Até aqui, sua hora vale ${moneyBRL(vh)}',
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: const BorderRadius.all(Radii.md),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(/* … igual, semanticLabel pode sair … */),
        ),
      ),
    ),
  ),
);
```

E, pra fechar a porta de vez, no widget que dá a garantia:

```dart
// core/ui/money_count_up.dart:57 — a doc diz "impossível de esquecer".
// `''` é justamente como se esquece.
assert(
  semanticLabel == null || semanticLabel!.isNotEmpty,
  'semanticLabel vazio APAGA o número do leitor de tela — ele não silencia a '
  'animação, ele tira o valor da árvore. Se for de propósito (outro nó já diz '
  'este número), envolva o MoneyCountUp em ExcludeSemantics: a intenção fica '
  'legível e o motivo fica no código.',
);
```

### P1-5 · `trabalho_detalhe_screen.dart:308` — o `ExcludeSemantics` come os pagamentos

O `Semantics(label: 'Em julho: recebeu X, separou Y')` cobre o `PanelCard`
inteiro sob `ExcludeSemantics` — **inclusive as linhas de detalhe das 341-353**,
que listam cada pagamento do mês.

Resultado: a tela que o dono descreveu literalmente — *"o Augusto me pagou 400
num mês, 600 no outro"* — dá o total do mês e **nunca os pagamentos individuais**
pra quem usa leitor de tela. E o rótulo não diz nem quantos foram. É o mesmo
defeito do `semanticLabel: ''`: silêncio pra evitar repetição, apagando conteúdo
que não tem outro canal.

```dart
// trabalho_detalhe_screen.dart:301 — o Exclude cobre só o que o label conta.
return Padding(
  padding: const EdgeInsets.only(bottom: Space.x3),
  child: PanelCard(
    padding: const EdgeInsets.all(Space.x4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MergeSemantics(
          child: Semantics(
            header: true,
            label:
                'Em ${mesAno(mes)}: recebeu ${moneyBRL(total)}, '
                'separou ${moneyBRL(separado)} de imposto'
                '${entradas.length > 1 ? ', em ${entradas.length} pagamentos' : ''}.',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(/* mesAno + total — igual */),
                  const SizedBox(height: Space.x1),
                  Text('separou ${moneyBRL(separado)} de imposto', /* igual */),
                ],
              ),
            ),
          ),
        ),
        // Fora do Exclude: cada pagamento é conteúdo, não decoração.
        if (entradas.length > 1) ...<Widget>[
          const SizedBox(height: Space.x2),
          for (final Entrada e in entradas)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${dataCurta(e.at)} · ${moneyBRL(e.valor)}',
                // dataCurta vira "dez barra ago" na fala; datas.dart:49 já
                // resolveu isso e o helper não estava sendo usado aqui.
                semanticsLabel: '${dataPorExtenso(e.at)}: ${moneyBRL(e.valor)}',
                style: /* … igual … */,
              ),
            ),
        ],
      ],
    ),
  ),
);
```

### P1-6 · `historico_screen.dart:201` — cada entrada é uma sopa de números

A linha da entrada é um `MergeSemantics` sobre três `Text` crus. O TalkBack lê:

> *"dez barra ago ponto médio Augusto, R cifrão quatrocentos, ponto médio R
> cifrão sessenta e oito"*

Nada diz que o segundo valor é o imposto separado. É a tela que a pessoa abre pra
conferir o próprio dinheiro.

```dart
// historico_screen.dart:201
for (final Entrada e in ordenadas)
  Semantics(
    label:
        '${dataPorExtenso(e.at)}'
        '${_nome(e) == null ? '' : ', ${_nome(e)}'}: '
        'recebeu ${moneyBRL(e.valor)}, '
        'separou ${moneyBRL(e.separado)} de imposto.',
    child: ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.x1),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(/* … igual … */)),
            const SizedBox(width: Space.x2),
            // Ver P1-8: sem isto a linha estoura 283px em fonte 2.0.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(moneyBRL(e.valor), /* … igual … */),
                    Text(' · ${moneyBRL(e.separado)}', /* … igual … */),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
```

### P1-7 · `trabalhos_screen.dart:113` e `:133` — a hierarquia latente não tem cabeçalho *(§4.1)*

Ver §4.1. Correção:

```dart
// trabalhos_screen.dart:112 — o cabeçalho de grupo precisa SER cabeçalho.
out
  ..add(
    Padding(
      padding: const EdgeInsets.only(top: Space.x2, bottom: Space.x2),
      child: Semantics(
        header: true,
        // A contagem é o que substitui, na fala, o "bater o olho e ver que são
        // três". Sem ela a pessoa precisa varrer o grupo inteiro pra saber
        // o tamanho dele.
        label:
            'Área ${area.nome}. '
            '${daArea.length} ${daArea.length == 1 ? 'trabalho' : 'trabalhos'}.',
        child: ExcludeSemantics(
          child: Text(
            area.nome.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
  )
  ..addAll(_planos(context, daArea, recebido, ultima));
```

E o mesmo em `:133` para os órfãos:
`label: 'Sem área. ${orfaos.length} ${orfaos.length == 1 ? 'trabalho' : 'trabalhos'}.'`.

### P1-8 · Fonte 200%: cinco estouros nas telas novas (WCAG 1.4.4)

Sonda: app real, `TextScaler.linear(2.0)`, tela de 320×640dp (Moto E / celular
barato, que é o público). Saída literal:

```
OK       Painel
ESTOURA  Trabalhos (lista)        -> RenderFlex overflowed by 45 pixels on the right
OK       Trabalho detalhe
OK       Entrada (vazia)
ESTOURA  Entrada (com resultado)  -> 390px  e  165px
ESTOURA  Histórico                -> 157px  e  283px
OK       Calc passo 1 · 2
ESTOURA  Calc passo 3             -> 351px  e  275px
OK       Marca
```

Com origem exata:

| arquivo:linha | quem estoura | o que se perde |
|---|---|---|
| `entrada_screen.dart:425` | `_legenda` — o `Row` do quadradinho + texto | **"Pra usar R$ 332" cortado.** É o canal textual que garante "cor nunca sozinha". Em fonte grande, morre o texto e sobra a cor |
| `historico_screen.dart:205` | a linha da entrada | o valor e o imposto ficam fora da tela |
| `calc_screen.dart:990` | `_PreviaValorHora` | o número vivo some pra quem aumentou a fonte |
| `calc_screen.dart:652` | `Total: R$ X /mês` | o total dos custos |
| `trabalhos_screen.dart:183` | o `Row` do card | **o valor recebido**, que é a razão do card existir |

Fonte grande é o recurso de baixa visão mais usado do mundo — muito mais que
leitor de tela. E o padrão é cruel: **o que some é sempre o número**, porque o
número está sempre do lado direito de um `Row` sem `Flexible`.

Correções (`entrada_screen.dart:420` como modelo — em `Wrap`, `Flexible` +
`softWrap` resolve):

```dart
Widget _legenda(BuildContext context, Color color, String label, double valor) =>
  Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(width: 12, height: 12, /* … igual … */),
      const SizedBox(width: Space.x2),
      Flexible(
        child: Text(
          '$label ${moneyBRL(valor)}',
          softWrap: true,
          style: /* … igual … */,
        ),
      ),
    ],
  );
```

```dart
// trabalhos_screen.dart:183 — o dinheiro encolhe, nunca vaza.
Row(
  children: <Widget>[
    Expanded(flex: 3, child: Column(/* nome + apoio — igual */)),
    const SizedBox(width: Space.x3),
    Flexible(
      flex: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(moneyBRL(recebido), maxLines: 1, /* … igual … */),
          ),
          Text('recebido', /* … igual … */),
        ],
      ),
    ),
  ],
)
```

`calc_screen.dart:652` e `:990`: `FittedBox(fit: BoxFit.scaleDown, alignment:
Alignment.centerLeft, child: Row(…))` em volta do `Row` inteiro.

**Sugestão de trava:** `overflow_test.dart` hoje cobre só a `DivisaoBar`. Vale
promover a sonda a teste de verdade — as cinco telas novas em 2.0 / 320dp,
`expect(tester.takeException(), isNull)`.

### P1-9 · `hero_value_card.dart:57` — o chip diz "Trabalho" e é Área

```dart
label: 'Trabalho ativo: $perfilNome',
hint: 'Toque duas vezes pra trocar de trabalho',
```

Depois da renomeação, isso está errado em dois eixos:

1. **Vocabulário.** O chip mostra `area.nome` e leva pra `Routes.areas`
   ("Meus preços"). Quem ouve "Trabalho ativo: Design" e cai numa tela de preços
   perde o modelo mental — e "Trabalho" é justamente o nome da OUTRA aba, onde
   mora o Augusto. É o pior sinônimo possível.
2. **O hint ensina o gesto, não o resultado.** O TalkBack já diz "toque duas
   vezes para ativar" sozinho; escrever isso no hint faz ele falar duas vezes. E
   pra quem usa Switch Access ou teclado, "toque duas vezes" é instrução falsa.
   Hint descreve **o que acontece**, nunca **como fazer**.

```dart
label: 'Área ativa: $perfilNome',
hint: 'troca a área e o valor-hora do Início',
```

### P1-10 · `marca_screen.dart:226` — os círculos de cor *(§4.5)*

Ver §4.5. Três defeitos num bloco: alvo de 44dp, contraste do círculo no tema
escuro (Grafite dá **1.94:1**), e escolha sem confirmação falada. Correção
completa em §4.5.

### P1-11 · `entrada_bar.dart:51` — a barra do caminho de ouro quebra a regra da casa

A `DivisaoBar` tem uma regra explícita e correta no próprio doc
(`divisao_bar.dart:16-19`): *"os segmentos se distinguem por FORMA — Custos leva
hachura, Reserva leva pontilhado (defesa deutan)"*. A `EntradaBar`, que é a barra
da tela mais usada do app, **não herdou isso**: são duas faixas chapadas.

Contraste medido entre os dois segmentos:

| tema | custo × reserva |
|---|---|
| claro | **1.16:1** |
| escuro | 1.73:1 |

No tema claro a barra é, na prática, um bloco só. E há uma colisão semântica em
cima disso: "Pra usar" (o dinheiro que é seu) está pintado de `d.custo` — a cor
que significa *custo* em todas as outras telas —, enquanto `d.lucro` (esmeralda
= "é seu") não aparece. A mesma ideia tem duas cores em duas telas.

```dart
// entrada_bar.dart:51 — mesma gramática da DivisaoBar: forma, não só cor.
// (Tornar `_HatchPainter`/`_DotPainter` de divisao_bar.dart públicos e mover
// pra core/ui/ — hoje são privados e é por isso que esta barra nasceu sem eles.)
Row(
  children: <Widget>[
    AnimatedContainer(
      duration: reduce ? Duration.zero : Motion.quick,
      curve: MotionCurves.standard,
      width: w * (1 - fR),
      color: d.lucro, // "Pra usar" é o que É SEU — esmeralda, como no resto
    ),
    const SizedBox(width: 2),
    SizedBox(
      width: w * fR,
      child: ColoredBox(
        color: d.reserva,
        child: CustomPaint(painter: DotPainter(hatch)), // Reserva = pontilhado
      ),
    ),
  ],
)
```

E as legendas de `entrada_screen.dart:350-361` acompanham (`d.custo` → `d.lucro`
na de "Pra usar").

### P1-12 · Foco se perde quando o botão troca de identidade *(§4.4)*

`entrada_screen.dart:368-396`. Ver §4.4.

### P1-13 · `marca_screen.dart:335` — a máscara de telefone joga o cursor pro fim

```dart
return TextEditingValue(
  text: texto,
  selection: TextSelection.collapsed(offset: texto.length),
);
```

Errou um dígito no meio do número? Não dá pra corrigir: qualquer edição no meio
teleporta o cursor pro fim. Quem tem tremor, dislexia ou está no ônibus com uma
mão erra no meio o tempo todo — e a saída vira "apaga tudo e digita de novo".

O `_MilharFormatter` (`money_field.dart:92-133`) **já resolveu isso** contando
dígitos antes do cursor, com comentário e tudo. A máscara nova não reaproveitou.
Correção: mesma técnica, ou extrair o cálculo do `_MilharFormatter` pra uma
função compartilhada `int offsetPreservandoDigitos(String bruto, int rawOffset,
String formatado)`.

---

## 3. P2 — polimento (pode esperar; anote e siga)

| # | onde | o quê |
|---|---|---|
| P2-1 | `app_theme.dart:128` | **`bodySmall` não está definido** no `TextTheme`. Ele cai no default do M3: 12sp, Roboto — não Inter. E carrega informação real em três telas novas (`trabalhos_screen:202` "Última entrada em…", `trabalho_detalhe:332` "separou X de imposto", `marca_screen:221` a explicação da cor). 12sp em `onSurfaceVariant` é o piso do legível pra baixa visão. Sugiro `bodySmall: s(13, 18, FontWeight.w400)` |
| P2-2 | `entrada_screen.dart:300-363` | O card do resultado fala o mesmo três vezes: o sobrolho `SEPARE PRO IMPOSTO`, o `semanticLabel` do `MoneyCountUp` ("Separe R$ 68 pro imposto"), o rótulo da `EntradaBar` e as duas legendas. Escolha **uma** fonte da verdade: `ExcludeSemantics` no sobrolho (linha 300) e na `EntradaBar` (que a legenda já repete em texto) |
| P2-3 | `entrada_screen.dart:229` | `autofocus: true` no `MoneyField` rouba o foco do TalkBack antes de ele anunciar o nome da tela ("Recebi de Augusto"). Vale manter o autofocus — ele é ouro pra todo mundo — mas gateado: `autofocus: !MediaQuery.accessibleNavigationOf(context)` |
| P2-4 | `config_screen.dart:48` | A aba se chama **Ajustes** e a tela se anuncia **"Configurações"**. Quem navega por fala confere o nome pra saber que chegou (WCAG 3.2.4). Escolha um |
| P2-5 | `marca_screen.dart:202` | O `errorText` do e-mail nasce **no primeiro caractere digitado** ("Isso não parece um e-mail") e nunca é anunciado — diferente do `MoneyField`, que anuncia (`money_field.dart:44-50`). Validar no `onEditingComplete`/perda de foco, e chamar `announce()` |
| P2-6 | app inteiro | Os sobrolhos (`ENTRADAS`, `ANOTAÇÕES`, `DE CADA MÊS`, `ESTE MÊS`, `COR DA SUA MARCA`, `SUA LOGO`) são `Text` comuns. Como `Semantics(header: true)` eles viram a navegação por seções do TalkBack — o "sumário" que quem não vê usa pra pular. Um `SecaoTitulo(String)` resolve todos de uma vez |
| P2-7 | `common/money.dart` | `moneyBRL` gera `R$ 1.234`, que serve pra tela e vai cru pros `announce()` e `Semantics`. TTS em pt-BR costuma dar conta, mas o ponto de milhar é aposta. Um `moneyFalado(num)` — *"mil duzentos e trinta e quatro reais"* — usado **só** nos rótulos e anúncios deixaria a fala fora do palpite. Baixa prioridade justamente porque o risco real é pequeno |

---

## 4. As quatro perguntas

### 4.1 A hierarquia latente: o leitor de tela entende a mudança de estrutura?

**Não. Hoje ele não vê estrutura nenhuma — nos dois modos.**

A ideia é ótima e eu a defenderia numa reunião: esconder um nível de hierarquia
de quem não precisa dele é exatamente o que reduz carga cognitiva. O problema é
que ela foi implementada **só no canal visual**.

Com 1 área, a lista é plana — e pra fala isso é perfeito. Nada a fazer.

Com 2+, o que muda visualmente é: aparece uma linha em caixa alta, cinza, menor,
com `letterSpacing`. Todos esses sinais de "isto é um cabeçalho de grupo" são
**tipográficos**. Na árvore de semântica, `trabalhos_screen.dart:116` é um `Text`
igual a qualquer outro. O TalkBack lê:

> "DESIGN" · "Augusto. Recebido…" · "Loja da Ana. Recebido…" · "FOTOGRAFIA" ·
> "Pedro. Recebido…"

Sem `header: true`, não há como pular de grupo em grupo (o gesto de navegação
por cabeçalhos é *o* jeito de varrer uma lista longa sem visão), não há como
saber onde um grupo termina, e "DESIGN" é ambíguo — pode ser um trabalho chamado
Design. A palavra "Área" não é falada em lugar nenhum, então a pessoa não tem
como saber que aquilo é **outro nível** e não mais um item.

Tem um agravante silencioso: **caixa alta.** Alguns motores de TTS soletram
palavras curtas em maiúsculas ("D-E-S-I-G-N"). O visual em caixa alta é decisão
de tipografia; o rótulo deve ir na grafia natural.

**Correção: P1-7.** Com `header: true` + o nome legível + a contagem, a mudança
de estrutura passa a existir na fala exatamente como existe na tela — e a
hierarquia continua latente pra quem tem uma área só, porque com uma área o
cabeçalho não é gerado. A ideia sobrevive inteira; ela só ganha o segundo canal.

**Um detalhe que você acertou e que vale proteger:** `trabalho_form_screen.dart:128`
só mostra o seletor de área quando `hierarquiaVisivel`. Sem isso, quem tem uma
área ouviria uma pergunta sobre um conceito que o app jurou não ter. Está certo.

---

### 4.2 O `_CofreDoMes`: está falando duas vezes ou de menos?

**De menos. E o raciocínio que levou ao `''` é meio certo — o que o torna
perigoso.**

A parte certa: você não quer que o número seja falado duas vezes. Concordo.

A parte errada é a premissa embutida: **`semanticLabel: ''` não é "não
anunciar". É "não ter nome".** São canais diferentes:

- **Anúncio** (`announce()`) é *transitório*. É um evento: "isto acabou de
  acontecer". Passa e some. Não tem histórico, não tem "repetir".
- **Rótulo** (`semanticLabel`) é *permanente*. É o nome do objeto, disponível
  toda vez que o dedo ou o swipe passa por ele.

Confirmei na sonda o que `''` produz:

```
id=4 label="" rect=86x20     <- o "R$ 412"
id=5 label="vizinho"
```

O nó existe, ocupa 86×20 pixels na tela e **não tem nome**. Na ponte Android
ele não é focável (sem rótulo e sem ação), então não vira uma parada em branco
irritante — vira **silêncio**. O `NO COFRE ESTE MÊS R$ 412` fica na tela pra
sempre e some da fala pra sempre.

A assimetria concreta: a pessoa que enxerga ouve o anúncio, e **depois pode
olhar de novo** — o número está lá. A pessoa que não enxerga ouve o anúncio uma
vez e, se estava no ônibus, se o TalkBack estava ocupado, se ela se distraiu, o
número **não existe mais em lugar nenhum**. Ela vai ter que sair da tela e ir ao
Histórico pra reencontrar o próprio acúmulo.

E o acúmulo é, pelo doc `08 §7`, a razão emocional de voltar mês que vem. Não é
detalhe: é a recompensa.

**A regra, e ela vale pro app inteiro:**

> **Anuncie a transição. Rotule o estado. Nunca deixe o estado sem nome pra
> evitar repetir a transição.**

Não há duplicação nisso: o `announce` diz *"você acabou de crescer 68"*, o
rótulo diz *"no cofre este mês: R$ 412"*. Frases diferentes, momentos
diferentes, canais diferentes.

**Sobre "conteúdo novo sem anúncio é armadilha":** você tem razão, e você já
resolveu. O `announce` de `entrada_screen.dart:173` cobre o nascimento da linha,
e cobre bem — a frase inclui o total acumulado, que é justamente o que a linha
nova mostra. **Não use `liveRegion: true` aqui.** Seria o terceiro canal falando
a mesma coisa, e `liveRegion` dispara em qualquer rebuild, não só neste.

**Correção: P1-3.** Uma linha.

---

### 4.3 O `_PreviaValorHora`: acerto ou esconder informação?

**Esconder informação — e o medo que motivou a decisão não se realiza.**

O `Text` do Flutter **não fala sozinho quando muda**. Só um nó com
`liveRegion: true` ou uma chamada a `SemanticsService` fazem isso. Um `Text`
comum, mesmo trocando de conteúdo 40 vezes enquanto a pessoa digita, é lido
**apenas quando recebe foco**. A tagarelice que você quis evitar nunca ia
acontecer.

O que o `''` fez de fato foi o mesmo do cofre: tirou o nome de um elemento
permanentemente visível. Do passo 3 em diante quem enxerga tem, no topo da tela,
*"até aqui: R$ 92 /hora"* — a promessa que transforma os passos finais de prova
em ajuste. Quem não enxerga tem **nada** ali. Ou seja: exatamente a pessoa que
mais precisa de confirmação de que os ajustes estão surtindo efeito é a que fica
sem o retorno.

E há um segundo problema no mesmo bloco, que a correção resolve de graça: hoje
são **três nós** (`"até aqui:"`, o número, `"/hora"`). Mesmo com rótulo, isso
seriam três paradas de swipe pra ler uma frase de quatro palavras — e `/hora`
seria lido como "barra hora". A correção junta tudo numa parada só e numa frase
falável.

**Onde o seu instinto está certo, e vale registrar:** existe uma tagarelice real
nesta tela, e ela está em outro lugar — o `_anunciar()` de
`entrada_screen.dart:120`, que fala de verdade a cada pausa de 900ms na
digitação. Aquilo **corta o eco de caractere do TalkBack** (não existe
`Assertiveness.polite` no Android). Não estou pedindo pra tirar — o retorno vivo
vale muito. Mas se um dia aparecer reclamação de "ele fala por cima de mim
enquanto digito", é esse timer, não o rótulo. E o cancelamento no save (P1-1) já
tira a pior versão do problema.

**Correção: P1-4.**

---

### 4.4 O Desfazer inline vs. a SnackBar: melhorou ou piorou?

**Melhorou muito. Foi a decisão certa. E está pela metade.**

**Por que a SnackBar era pior — três motivos, um deles é falha formal de WCAG:**

1. **Ela some sozinha em ~4s.** Isso é WCAG 2.2.1 (Timing Adjustable) na cara.
   Quem usa TalkBack precisa: ouvir o anúncio, entender, fazer swipe até
   encontrar o "Desfazer", tocar duas vezes. Em 4 segundos, com sorte, ela ouviu
   o anúncio. A ação existia mas era **inalcançável na prática**.
2. **O conteúdo dela não é anunciado de forma confiável** — o próprio código já
   sabia disso (`entrada_screen.dart:171`).
3. Ela flutua sobre o conteúdo, então nem a ordem de foco ajuda a encontrá-la.

O inline mata os três: **não tem prazo**, está na ordem de leitura, e fica logo
depois do card que acabou de mudar. Isso é acessibilidade boa por construção, não
por remendo — mantenha.

**O que falta pra fechar (P1-12):**

**a) O foco cai no vazio na troca.** Quando `_saved` vira `true`, o
`FilledButton.tonal('Guardar')` **é destruído** e nasce um `Row` com dois botões
novos. Se o foco do TalkBack estava no "Guardar" — e estava, a pessoa acabou de
apertá-lo — o nó desaparece debaixo dela. O TalkBack recai no início da tela ou
num vizinho arbitrário. A mesma coisa acontece de novo no `_desfazer`, na volta.

**b) "Desfazer" sozinho não diz desfazer o quê.** Fora de contexto: *"Desfazer,
botão"*. Desfazer o quê? O registro? O trabalho que nasceu? Tudo?

```dart
// entrada_screen.dart:368
if (_saved)
  Row(
    children: <Widget>[
      Expanded(
        child: FilledButton.tonal(
          focusNode: _focoDepoisDoSave, // pro foco ter onde pousar
          onPressed: () { /* … igual … */ },
          child: const Text('Registrar outro'),
        ),
      ),
      const SizedBox(width: Space.x3),
      Semantics(
        // O rótulo diz o que se perde. "Desfazer" sozinho é um cheque em branco.
        label: _ultima == null
            ? 'Desfazer'
            : 'Desfazer o registro de ${moneyBRL(_ultima!.valor)}',
        button: true,
        onTap: _desfazer,
        child: ExcludeSemantics(
          child: TextButton(onPressed: _desfazer, child: const Text('Desfazer')),
        ),
      ),
    ],
  )
```

E, no fim de `_salvar` (depois do `setState`):

```dart
// O botão que a pessoa apertou deixou de existir. Sem isto o foco do TalkBack
// volta pro topo da tela e o "Desfazer" vira um botão que ninguém acha.
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) _focoDepoisDoSave.requestFocus();
});
```

Simétrico em `_desfazer` (foco volta pro "Guardar") e no "Registrar outro" (foco
volta pro `MoneyField`, que hoje é limpo sem avisar ninguém — passe um
`focusNode` pro `MoneyField`, o widget já aceita).

**Um bônus da mudança que vale registrar:** o `Desfazer` da SnackBar sobrevive
em `trabalho_detalhe_screen.dart:269` (apagar trabalho) e em
`areas_screen.dart:179` (apagar área) — as duas ações **destrutivas e sem
confirmação por diálogo** do app. Ali o prazo de 4s dói ainda mais, porque o
custo de perder a janela é maior. Não é escopo desta auditoria, mas é o próximo
alvo do mesmo raciocínio.

---

### 4.5 Os círculos de cor: alvo, rótulo, e escolher sem enxergar cor

Três achados. O terceiro é o que eu não esperava encontrar.

**a) Alvo de 44dp — abaixo do piso da casa.**
`marca_screen.dart:242-243`: `width: 44, height: 44`. Passa em WCAG 2.5.8
(24×24), reprova nos 48dp do Material e da régua do próprio app. Com `spacing:
Space.x3` (12dp) entre eles, dedo grande em ônibus balançando erra de cor. Fácil:
alvo de 48, pintura de 44.

**b) Contraste do círculo no tema escuro — o achado sério.**
Contraste de cada cor da paleta contra o fundo, calculado sobre
`CorMarca.paleta`:

| cor | claro (#F4F3EE) | escuro (#101312) |
|---|---|---|
| Verde | 4.65 | 3.61 |
| Azul | 5.82 | **2.89** |
| Roxo | 6.65 | **2.53** |
| Magenta | 5.59 | **3.01** |
| Vermelho | 5.88 | **2.86** |
| Laranja | 4.32 | 3.90 |
| Ocre | 4.42 | 3.80 |
| **Grafite** | 8.68 | **1.94** |

A paleta foi curada pra funcionar **como acento sobre papel branco** — e nisso
ela é excelente (`cor_marca.dart:18-20` explica o critério, e o critério está
certo). Só que o seletor está num app cujo **tema padrão é escuro**. E a borda
que deveria dar o contorno é `cs.outlineVariant`, que dá **1.41:1** contra o
fundo escuro.

Resultado prático: no escuro, **"Grafite" é um buraco preto sobre fundo preto,
com contorno invisível**. Pra quem tem baixa visão, essa opção não existe. Azul,
Roxo, Vermelho e Magenta ficam abaixo de 3:1 — reprovam em WCAG 1.4.11
(Non-text Contrast), que é justamente o critério para "o componente é
identificável".

A correção é uma linha de cor: `cs.outline` dá **4.55:1** no escuro e **4.81:1**
sobre o card claro. O contorno passa a ser o que faz cada opção existir.

**c) Como alguém que não enxerga cor escolhe uma — e a resposta surpreendente.**

Aqui você já ganhou a parte difícil, e acho que sem perceber:

1. **O nome está no rótulo** (`label: c.nome`). É o canal não-visual, e ele
   existe. Nome de cor não é decorativo — é *a* forma de escolher sem ver. Ponto
   pra você.
2. **O selecionado não é sinalizado só por cor**: tem ícone de check + borda de
   3px + `selected: true` no `Semantics`. Três canais. Ponto de novo.
3. **E o principal**: `CorMarca.serveComoFundo()` (`cor_marca.dart:67`) garante,
   por cálculo de contraste, que **nenhuma escolha produz um documento
   ilegível**. Quem não vê cor pode escolher qualquer uma às cegas e o PDF sai
   legível para o cliente dela. Isso é acessibilidade estrutural — o tipo que
   funciona sem a pessoa saber que existe. É a coisa mais bem-feita desta
   auditoria inteira. **Não mexa.**

O que falta é pequeno em código e grande em experiência: **a escolha não é
confirmada.** Toca em "Roxo", sai um `Haptics.select()` e mais nada. Sem visão,
"escolhi alguma coisa" ≠ "escolhi Roxo". E a semântica devia ser de rádio, não
de botão: `inMutuallyExclusiveGroup` + `checked` faz o TalkBack falar
*"Roxo, marcado"* em vez de *"Roxo, selecionado, botão"*.

```dart
// marca_screen.dart:226
Wrap(
  spacing: Space.x3,
  runSpacing: Space.x3,
  children: <Widget>[
    for (final ({String nome, int valor}) c in CorMarca.paleta)
      Semantics(
        // Escolha de um-entre-N é rádio, não botão: o TalkBack anuncia
        // "marcado / não marcado" e a posição no grupo.
        inMutuallyExclusiveGroup: true,
        checked: _cor == c.valor,
        label: 'Cor ${c.nome}',
        onTap: () => _escolherCor(c),
        child: ExcludeSemantics(
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _escolherCor(c),
            // Alvo de 48dp; a joia continua com 44.
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(c.valor),
                    shape: BoxShape.circle,
                    // outlineVariant dá 1.41:1 — no tema escuro, Grafite
                    // (1.94:1 contra o fundo) simplesmente desaparece.
                    // outline dá 4.55:1 e faz a opção existir.
                    border: Border.all(
                      color: _cor == c.valor ? cs.onSurface : cs.outline,
                      width: _cor == c.valor ? 3 : 1.5,
                    ),
                  ),
                  child: _cor == c.valor
                      ? Icon(
                          Icons.check,
                          size: 20,
                          color: CorMarca.textoSobre(c.valor),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
  ],
)
```

```dart
void _escolherCor(({String nome, int valor}) c) {
  Haptics.select();
  setState(() => _cor = c.valor);
  // Vibrar diz "algo aconteceu". Só a fala diz O QUÊ.
  announce(context, 'Cor ${c.nome} escolhida.');
}
```

---

## 5. Alvos de toque e ordem de foco — a varredura

**Alvos ≥48dp.** O tema já garante o piso onde importa
(`app_theme.dart:36-56`): `FilledButton`/`OutlinedButton` 56dp,
`TextButton` **48×48**. `IconButton` é 48 por default do Material.
`ListTile` com `minVerticalPadding: 12` passa. Os steppers da calc pedem 52dp
explicitamente (`calc_screen.dart:477`). O chip do herói força
`minHeight: 48` com comentário (`hero_value_card.dart:66-68`).

Nas telas novas achei **um** furo: os círculos de cor (44dp, §4.5). O resto está
limpo — e limpo por decisão de tema, que é o jeito certo de garantir isso.

**Ordem de foco.** Todas as telas novas são `ListView`/`Column` em ordem
visual, sem `Stack` competindo e sem `Positioned` fora de fluxo. A ordem de
travessia sai correta de graça — **não precisa de `FocusTraversalGroup` nem de
`SemanticsSortKey` em lugar nenhum**. Verifiquei os oito arquivos.

Duas ressalvas, ambas já listadas:
- `_PreviaValorHora` (`calc_screen.dart:239`) fica **acima** do conteúdo do
  passo, então é a primeira parada. Visualmente correto, e na fala fica "R$ 92
  por hora" antes da pergunta do passo. Aceitável — é uma faixa de contexto,
  como um cabeçalho. Não mexeria.
- Foco perdido nas trocas de botão do `entrada_screen` — P1-12.

**Reduce motion.** `reduceMotionOf()` é consultado nas transições de rota
(`router.dart:47/78`), no `StaggerIn`, no `PressableScale`, no `MoneyCountUp`,
no `AnimatedSwitcher` da entrada, no `AnimatedSize` do cofre, na `EntradaBar` e
na `DivisaoBar`. Procurei animação sem gate nas telas novas e **não achei
nenhuma**. Isso é raro. Está travado por teste
(`reduce_transparency_test.dart`, `nav_glass_test.dart`).

---

## 6. O que está bom — não mexa

Isto não é gentileza de encerramento. São decisões que eu defenderia numa
auditoria de banco, e que quebram fácil quando alguém "arruma" o arquivo.

1. **`CorMarca.serveComoFundo()` / `textoSobre()`** (`cor_marca.dart:56-68`).
   O app calcula contraste e escolhe preto ou branco por cima da cor da pessoa,
   e recusa usar como fundo de texto qualquer cor abaixo de 4.5:1. Nenhuma
   escolha do usuário consegue produzir um documento ilegível pro cliente dele.
   Acessibilidade que funciona sem ninguém saber que existe. **O melhor código
   de a11y do repositório.**

2. **`announce()` centralizado** (`a11y.dart`) e a regra declarada *"todo momento
   que VIBRA ou ANIMA também FALA"*. É o tipo de regra que faz a a11y sobreviver
   à próxima feature. Ela está sendo cumprida: erro de nome de área
   (`areas_screen.dart:297`), erro de custo (`calc_screen.dart:790`), mudança de
   passo (`:158`/`:181`), regime escolhido (`:893`), logo escolhida
   (`marca_screen.dart:67`), Pro ativado (`areas_screen.dart:236`).

3. **`MoneyField` anuncia o `errorText` sozinho** (`money_field.dart:44-50`).
   "Erro visível ≠ erro percebido" resolvido numa camada, pra toda tela de uma
   vez, em vez de repetido em oito lugares.

4. **`_TrabalhoCard._semantica()`** (`trabalhos_screen.dart:245`). Uma parada,
   uma frase completa, `dataPorExtenso` em vez de `dataCurta`, e o "Encerrado"
   incluído. É exatamente como se escreve o rótulo de um card. Copie este.

5. **`dataPorExtenso()`** (`datas.dart:49-52`) existir, com o comentário
   explicando que "10/ago" vira "dez barra ago". Alguém pensou em fala antes de
   precisar. (Ele só não está sendo usado em dois lugares — P1-5 e P1-6.)

6. **Contraste de texto.** Medi 23 pares críticos dos dois temas. **Todos passam
   AA**, a maioria com folga: o pior é `reserva` sobre papel (4.62:1), o típico
   fica entre 5 e 10. Números pequenos em `onSurfaceVariant` — o lugar onde
   todo app escorrega — dão 7.38:1 no claro e 8.82:1 no escuro. Isso não
   acontece por acaso.

7. **A `DivisaoBar` distinguir segmentos por forma** (hachura/pontilhado), com o
   raciocínio deutan escrito no código (`divisao_bar.dart:16-19`). Está certo e é
   raro. É por isso que a `EntradaBar` não ter herdado (P1-11) me incomoda: o
   padrão certo existe e a tela mais usada ficou de fora.

8. **A navbar cair pro sólido com `accessibleNavigation` ou reduce-transparency**
   (`nav_shell.dart:57-60`), mantendo a `NavigationBar` **nativa** por dentro do
   vidro — a semântica de aba do TalkBack preservada. Vidro real sem sacrificar
   a semântica é difícil; foi feito certo e travado por teste.

9. **`StaggerIn` com `alwaysIncludeSemantics: true`** (`motion.dart:96`). Uma
   linha que impede o TalkBack de varrer uma lista ainda invisível e achar que
   ela está vazia. Detalhe que 99% dos apps erram.

10. **A escala de fonte do app multiplicar a do sistema em vez de substituir**
    (`text_scale.dart:3-4`, com o comentário *"nunca substitui o zoom do sistema
    (baixa visão) — combina"*). É a diferença entre respeitar e sequestrar a
    configuração de acessibilidade da pessoa.

11. **O `Desfazer` ter saído da SnackBar** (§4.4). Independente do que falta pra
    fechar, a direção é a certa e resolve uma falha formal de WCAG 2.2.1.

12. **A tela vazia de Trabalhos** (`trabalhos_screen.dart:259`) explicar o modelo
    ("registre e diga de quem veio — o trabalho aparece aqui sozinho") em vez de
    só mostrar um botão. Pra quem tem TDAH ou está entendendo o app pela
    primeira vez, essa frase é o produto.

---

## 7. A ordem que eu seguiria

**Antes de qualquer pessoa com deficiência usar isto:**
P0-1 (áreas inacessíveis) · P0-2 (a ação dos cards) · P0-3 (o crash em debug).
São três correções pequenas; a maior é o `SemanticButton`.

**Antes de lançar:**
P1-1, P1-2 (a fala e o clique duplo no caminho de ouro) · P1-3, P1-4 (os dois
`semanticLabel: ''`) · P1-5, P1-6 (o conteúdo comido pelo `ExcludeSemantics`) ·
P1-7 (os cabeçalhos de área) · P1-8 (os cinco estouros em fonte 200%) · P1-10
(os círculos) · P1-12 (o foco no Desfazer).

**Depois, sem pressa:**
P1-9, P1-11, P1-13 e todos os P2. O P2-7 (moeda falada) só se aparecer
reclamação real — é o tipo de rigor que atrasa lançamento e conserta um problema
que talvez não exista.

E um pedido: a sonda de fonte 200% (§P1-8) merece virar `test/text_scale_screens_test.dart`.
Estouro de layout volta sozinho toda vez que alguém acrescenta uma palavra numa
`Row`, e é o defeito de acessibilidade mais fácil de flagrar automaticamente.
