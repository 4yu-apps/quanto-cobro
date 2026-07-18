# Quanto Cobro? — Personas, Jobs-to-be-done e cenários

> Quem usa, o que cada um quer resolver, e o que faz dentro do app. Personas derivadas da
> [voz real do freelancer](../research/raw/D-demanda-voz-real.md) (Reddit/fóruns) e da
> [análise de 16,9k reviews](../research/ANALISE-QUANTITATIVA-REVIEWS.md).

---

## 1. Jobs-to-be-done (as três perguntas do app)

| Job | Gatilho | Ritmo | Tela-núcleo |
|---|---|---|---|
| **J1 — Quanto cobrar por hora** | vou fechar um trabalho / revisar preço | raro (estratégico) | Calculadora guiada |
| **J2 — Quanto guardar deste pagamento** | acabei de receber | **recorrente** (motor de hábito) | Reserva |
| **J3 — Esse projeto dá lucro?** | me mandaram um valor / vou orçar | recorrente | Simulador |

> **A virada da [proposta](00-PROPOSTA-DE-PRODUTO.md):** J2 e J3 (recorrentes) são o coração
> do produto; J1 é o setup estratégico. O modelo antigo apostava peso demais no J1.

---

## 2. Personas

### P1 · Bruno, o iniciante ansioso (dev/design começando no freela)
- **Perfil:** 24–32, saiu/está saindo do CLT ou faz bico, primeiro cliente grande chegando.
  Profissão mais vocal no Reddit BR sobre isso: **dev/TI**, seguido de design.
- **Dor (verbatim):** *"Sou dev e quero começar no freela, mas não sei por quanto cobrar."* ·
  *"Cobrei 6k por um sistema, meus chefes cobrariam 50k, tomei um puta preju."*
- **O que quer no app:** descobrir um valor-hora **digno** em poucos minutos, sem planilha,
  e entender por que não é "renda ÷ 160h".
- **Job primário:** J1. **Secundário:** J3 (validar o primeiro projeto).
- **Sucesso:** sai com um número que ele **confia o bastante pra mandar na proposta**.

### P2 · Camila, a freela em atividade (social media / redatora / fotógrafa)
- **Perfil:** 25–40, já vive de freela há 1–3 anos, vários clientes, renda irregular. Segmentos
  de alto volume: **social media/tráfego**, redação, fotografia.
- **Dor:** *"cobrando barato demais"*, *"precificação é sempre aquele nó"*, e nunca sabe se de
  fato sobra depois de custo e imposto.
- **O que quer:** clareza recorrente — a cada pagamento, ver **quanto é dela, quanto é do
  leão, quanto foi custo**. Não quer refazer conta; quer tocar uma vez.
- **Job primário:** J2 (recorrente). **Secundário:** J3. **É a persona da virada** — a que o
  modelo antigo retinha mal.
- **Sucesso:** vira hábito abrir o app quando o PIX cai.

### P3 · Diego, o recém-MEI (formalizou e se assustou)
- **Perfil:** 28–45, acabou de abrir MEI ou migrar do CPF, descobriu que tem imposto/DAS.
- **Dor:** *"descobri que tinha que declarar... paguei os boletos com as multas por atraso."* ·
  medo de estourar o teto do MEI.
- **O que quer:** saber **quanto separar** e não esquecer; entender o impacto do regime sem
  jargão. Table-stakes: lembrete de vencimento.
- **Job primário:** J2. **Secundário:** J1 (recalcular preço agora que tem imposto).
- **Sucesso:** para de ter medo do imposto porque sabe que está guardando o suficiente.

### P4 · Marina, a freela pra gringo (recebe em USD via Fiverr/Deel/Wise)
- **Perfil:** 25–40, dev/design/redação para clientes no exterior, recebe em dólar.
- **Dor:** *"o Leão tá comendo muito do que ganho"*, carnê-leão é onde a dor tributária pega
  mais forte (renda variável, câmbio, obrigação mensal).
- **O que quer:** reservar certo em modo internacional, com moeda, e não ser pega de surpresa.
- **Job primário:** J2 (modo intl). **Diferencial de nicho** pouco atendido.
- **Sucesso:** recebe em dólar e já sabe, em segundos, quanto é dela de verdade.

> **Anti-persona (fora de escopo):** o confeiteiro/artesão que precifica **produto**. Job
> diferente (matéria-prima, markup de varejo). Bem servido por PeqArt/Doce Lucro. Não é nosso.

---

## 3. Possibilidades de uso (o que cada um faz dentro do app)

Cenários concretos, ligados às telas ([IA completa em 03](03-ARQUITETURA-DE-INFORMACAO.md)):

| # | Situação real | Persona | Fluxo no app | Toques |
|---|---|---|---|---|
| C1 | "Vou mandar proposta hoje, quanto cobro?" | Bruno | Vazio → Calculadora (5 passos) → Resultado → salvar | ~7 |
| C2 | "Caiu R$ 2.000, quanto é meu?" | Camila | Painel → Recebi um pagamento → vê Reserva + Divisão | **2** |
| C3 | "Me ofereceram R$ 3.000 por 30h, vale?" | Bruno/Camila | Painel → Vou orçar → lucro real + aviso se abaixo do alvo | 3 |
| C4 | "Virei MEI, muda o que eu guardo?" | Diego | Recalcular/Config → regime → reserva % se ajusta | 3 |
| C5 | "Recebi US$ 500 do cliente gringo" | Marina | Reserva → modo intl → reserva em % + sobra | 2–3 |
| C6 | "Como o app chegou nesse R$ 92?" | todos | Painel → ver como cheguei → detalhamento editável | 2 |
| C7 | "Quero mandar um orçamento bonito pro cliente" | Camila (Pro) | Simulador/Resultado → exportar PDF | 2 (gatilho Pro) |
| C8 | "Tenho cliente fixo e projeto avulso com preços diferentes" | Camila (Pro) | Perfis → alterna cenário | 2 |
| C9 | "Vou trocar de celular, não quero perder tudo" | Diego | Config → backup/exportar (pedido recorrente da fase 2) | 2 |

> **Caminho de ouro (o que define retenção):** **C2** — 2 toques do Painel ao "reserve isto".
> Se esse fluxo não for instantâneo e satisfatório, o app vira "abri uma vez". É a régua.

---

## 4. O que cada persona valoriza (para priorizar features)

- **Todos:** simplicidade (20% dos elogios do mercado), resolver a dor de forma visível
  (38%), offline/sem cadastro, estabilidade (bug é a queixa nº1).
- **Bruno:** didática das horas faturáveis (o "estimar pra mim"); default de valor-hora digno.
- **Camila:** velocidade do recorrente; PDF de orçamento; vários perfis.
- **Diego:** número mastigado por regime; lembrete de vencimento; não estourar teto MEI.
- **Marina:** modo internacional; moeda; reserva recorrente.

---

*Próximo: [03 — Arquitetura de Informação](03-ARQUITETURA-DE-INFORMACAO.md) traduz esses jobs
e cenários em telas concretas.*
