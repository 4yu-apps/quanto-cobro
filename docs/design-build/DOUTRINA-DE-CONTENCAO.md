# Doutrina de Contenção — como o app deixa de ter "cara de IA"

> **O que é:** uma camada de *disciplina* sobre o Design System que já existe. Não
> troca paleta, nem token, nem fonte — o DS está certo. Ela corrige o **uso**: hoje
> o app distribui destaque demais (card brilhante em tudo), e é isso que dá o
> aspecto de layout gerado por IA. Aqui ficam as regras que devolvem hierarquia.
>
> **Status:** aprovada em conceito (23/07/2026). Validando primeiro em **HTML**
> (`docs/design-reference/mock-hierarquia.html`) antes de portar pro Flutter.

---

## 1. O defeito, nomeado

A Painel (pós-cálculo) empilha 4–5 superfícies "premium" com glow competindo:
`HeroValueCard` + 2× `ToolActionCard` (com accent) + `_CardDoMes` (glow) +
`PanelCard` da Divisão (glow). Cada bloco grita "sou importante" → **nenhum é**.
Profusão sem prioridade = a assinatura de UI de IA. O `PanelCard` com glow é lindo
**quando é raro**; aplicado em tudo, vira ruído.

---

## 2. As seis leis

1. **Orçamento de glow: 1 por tela.** Só o herói ganha superfície com accent+glow
   (`PanelCard` com `accent`). Todo o resto é `surfaceContainer` **plano** — só o
   fio-de-luz de 1px, sem glow de acento. A hierarquia vem do **tom de superfície**,
   não de brilho (já é o que o color-guide manda; a doutrina só faz cumprir).

2. **Um herói por tela.** Um único número/elemento manda. Na Painel: o **valor-hora**
   é o herói; "guardei esse mês", Divisão e ações **descem** de nível. Dois heróis
   brigando = zero herói.

3. **60 · 30 · 10 (a regra do Mario).**
   - **60%** = canvas escuro calmo + texto neutro. A maior parte respira.
   - **30%** = superfícies de apoio **planas** (chart, linhas, track da Divisão).
   - **10%** = acento (verde) — só no número-herói e no **um** CTA primário. Cor de
     significado (ouro/aço/terracota) entra só na Divisão e em selos, nunca em texto.

4. **Nem tudo é card.** O jeito mais rápido de parecer IA é empilhar cards iguais. A
   variedade é o que dá vida: **número solto** no canvas (sem caixa), **um gráfico**
   (barras finas do mês), **um elemento circular** (anel de reserva / o `cofre_mark`),
   **imagens/avatares** (trabalhos como iniciais coloridas), **linhas planas** (lista).
   Olhar tem que ter ritmo, não uma pilha de retângulos.

5. **Hierarquia de número.** Herói: número grande (Sora) + centavos sobrescritos
   menores + rótulo minúsculo em CAPS (`onSurfaceVariant`). Números secundários
   **menores e neutros** — nunca coloridos. Só o herói pode usar a cor de marca.

6. **Personalidade por UM elemento assinatura, não por sparkle.** O `cofre_mark` é o
   nosso "saco de dinheiro" (como o do app de crypto, como o Mario é o Mario). Marca
   forte cercada de calma — não glow espalhado.

---

## 3. Variedade de componentes (o antídoto do card-soup)

Cada tela deve misturar pelo menos 3 naturezas diferentes de elemento:

| Natureza | Exemplo no app | Onde |
|---|---|---|
| Número solto | valor-hora no canvas, sem caixa | herói da Painel/Reserva |
| Gráfico | barras finas "este mês, mês a mês" | Painel |
| Circular | anel de % da reserva · `cofre_mark` | Painel / Reserva |
| Avatar/imagem | trabalhos como iniciais coloridas | Meus Trabalhos |
| Linha plana | lista de trabalhos/histórico | Trabalhos / Histórico |
| Barra segmentada | a Divisão (lucro/reserva/custo) | todas as de resultado |

---

## 4. Dois bugs de fluxo que entram junto

- **Reserva salva e fica na tela oferecendo "recebi de outro":** sem sentido. Salvou
  = **sai** (vai pra Meus Trabalhos / Painel com o feedback). Remover "registrar outro".
- **Meus Trabalhos é lista chapada sem herói:** aplicar a doutrina — um destaque
  (total ou trabalho em foco) + linhas planas.

---

## 5. O que esta doutrina NÃO faz
- Não muda paleta, token, fonte, nem o color-guide.
- Não é pra aplicar às cegas: valida no HTML, depois porta pro Flutter tela a tela.
- Não proíbe o `PanelCard` com glow — só o **raciona** (1 por tela).

---

*Próximo: mock HTML aplicando isto na Painel + Meus Trabalhos + Reserva. Se aprovar
o visual, porto pro Flutter tela a tela, sem tocar no DS.*
