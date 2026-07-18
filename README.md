# 💸 Quanto Cobro?

> Calculadora do freelancer BR: preço/hora, imposto a reservar e lucro real — por regime (MEI/CPF/Simples).

## Sobre

App Flutter para autônomos brasileiros responderem três perguntas essenciais: (1) quanto cobrar por hora para bater a renda desejada; (2) quanto reservar de cada recebimento para imposto; (3) lucro real após custos e tributos. Considera o contexto BR (MEI/DAS, autônomo CPF, Simples) + modo internacional. 100% offline.

**Problema que resolve:** Dois erros gêmeos do freelancer: cobrar de menos (ignora custos invisíveis) e não reservar para imposto. Transforma uma conta angustiante em 3 campos.

**Monetização:** AdMob (banner) + Pro de compra única (vários perfis de cliente/projeto, exportar orçamento em PDF, modo avançado por regime). Público profissional converte bem.

## Categoria

Finanças

## Tecnologia

Flutter · 100% offline · alíquotas locais (DAS, Simples, IRPF)

## Design & docs de referência

O pensamento de produto já está adiantado (saída dos agentes 1–3 da fábrica 4YU):

- [`docs/UX-Blueprint.md`](docs/UX-Blueprint.md) — arquitetura da informação, sitemap
  hub-and-spoke, inventário de telas, matriz de estados, fluxos e trade-offs.
- [`docs/Design-System.md`](docs/Design-System.md) — identidade visual e tokens.
- [`docs/design-reference/`](docs/design-reference/) — protótipo do Claude Design
  (HTML/JSX/CSS + mockups). É **especificação visual**, não código-fonte: o app é
  reescrito em Flutter idiomático (regra da casa, ver `PADRAO-4YU-APPS.md`).

## Status

🔎 **Descoberta de produto** — antes de codar, mineração de reviews de concorrentes
(BR + internacionais) para validar/enxugar o blueprint. Nome de exibição ainda em
validação (o identificador técnico `quanto-cobro` é estável). Equipe [4YU Apps](https://linear.app/4yu-apps).
