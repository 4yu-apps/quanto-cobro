# Planejamento de produto — Quanto Cobro?

Pacote de planejamento que transforma a pesquisa ([fase 1](../research/SINTESE-PESQUISA-CONCORRENTES.md)
+ [fase 2 — 16,9k reviews](../research/ANALISE-QUANTITATIVA-REVIEWS.md) + [sizing](../research/raw/F-mercado-sizing.md)
+ [teardown/monetização](../research/raw/G-teardown-monetizacao.md)) em decisões concretas de
produto — **antes** de qualquer cor, botão ou layout.

## A decisão central

O modelo atual acerta a estrutura, mas aposta peso demais no **cálculo do valor-hora** (uso
raro). A virada: promover **"A Divisão"** (mostrar pra onde vai cada real) a coração do
produto, com a **reserva por pagamento** (recorrente) como caminho de ouro. Isso pega mais
gente — não só o iniciante que pergunta "quanto cobro?", mas o freela em atividade que quer
saber, a cada pagamento, o que é dele.

## Os documentos (leia nesta ordem)

| # | Documento | O que responde |
|---|---|---|
| 00 | [Proposta de produto](00-PROPOSTA-DE-PRODUTO.md) | Qual modelo vence, posicionamento, quem pega/não pega, por que vence |
| 01 | [Mapa de oportunidades](01-MAPA-DE-OPORTUNIDADES.md) | Tamanho do mercado + todas as oportunidades priorizadas + onde NÃO ir |
| 02 | [Personas & Jobs](02-PERSONAS-E-JOBS.md) | Quem usa, o que quer, e o que faz dentro do app (cenários) |
| 03 | [Arquitetura de Informação](03-ARQUITETURA-DE-INFORMACAO.md) | O "sitemap" do app: telas, objetivo, conteúdo e cenários de cada uma |
| 04 | [Diferenciais & regras da casa](04-DIFERENCIAIS-E-REGRAS.md) | Por que escolher o nosso + o que nunca fazer (anti-★1) |
| 05 | [Escopo & roadmap](05-ESCOPO-E-ROADMAP.md) | MVP/Pro/futuro + modelo de monetização |
| 06 | [Fundação técnica](06-FUNDACAO-TECNICA.md) | Stack, dados locais, decisões de engenharia |
| 07 | [Proposta & gestão](07-PROPOSTA-E-GESTAO-DE-PROJETOS.md) | Proposta em PDF + a gestão ancorada na reserva |
| **08** | **[PLANO OFICIAL](08-PLANO-OFICIAL.md)** | **⭐ O documento vigente: as fases, o inventário de defeitos e as decisões abertas** |

### Revisões que corrigem os documentos acima

| Pasta | O que tem |
|---|---|
| [`ux-revisao/`](ux-revisao/) | Três especialistas de UX (modelo/IA · fluxo · motion) sobre o app construído |
| [`produto/`](produto/) | Dois donos de produto relendo os 16.961 reviews de forma independente |

> ⚠️ **Antes de citar número dos docs 00 e 05:** os dois carregam correções de
> auditoria (19/07/2026). O 4,42★ da categoria "precificação" vem de apps de
> precificação de **produto** (confeitaria/artesanato), não da nossa persona; e
> a âncora de preço usada é de um SaaS de gestão, categoria que decidimos não
> ser. Os avisos estão dentro dos próprios documentos.

## Como este pacote se conecta ao resto

- **Entrada:** [UX Blueprint](../UX-Blueprint.md) (IA/telas) + [Design System](../Design-System.md)
  (marca, "A Divisão", tokens) + [protótipo](../design-reference/) + pesquisa.
- **Saída:** base para atualizar o Blueprint (virada da ênfase) e para o Agente 4 (Flutter)
  scaffoldar o app.
- **Fora de escopo aqui (de propósito):** cor, tipografia final, layout de tela — vêm depois,
  já orientados por esta estrutura.

## Decisões em aberto (dependem do Gabriel)

1. **Validar a virada** (Divisão/reserva como coração) — é a tese central da proposta.
2. **Nome** — hoje "decidir depois". Não bloqueia o build; bloqueia a loja.
3. **Preços do Pro** — hipótese calibrada com benchmark; confirmar/testar.
4. **Escopo do MVP** — confirmar o corte grátis × Pro do [05](05-ESCOPO-E-ROADMAP.md).
