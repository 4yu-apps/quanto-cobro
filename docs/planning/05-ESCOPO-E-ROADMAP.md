# Quanto Cobro? — Escopo, roadmap e monetização

> Do mapa de oportunidades para versões concretas + o modelo de negócio, calibrado com
> [benchmarks de monetização](../research/raw/G-teardown-monetizacao.md) e
> [sizing de mercado](../research/raw/F-mercado-sizing.md).

---

## 1. Princípio de escopo: um problema, bem feito

Vencemos por **foco + confiança + simplicidade**, não por quantidade de recurso. Cada versão
resolve os jobs sem inflar. O inchaço (virar ERP/gestão completa) é justamente o que afunda os
concorrentes (bug, complexidade, ★1).

---

## 2. MVP (v1) — o que faz o app valer a pena

**Objetivo:** entregar os 3 jobs com a Divisão como coração, offline, estável, sem cadastro.

| Feature | Job / Oportunidade | Grátis/Pro |
|---|---|---|
| Calculadora guiada 5 passos → 3 respostas | J1 · O1 | Grátis |
| Helper "estimar pra mim" (horas faturáveis) | J1 · O1 | Grátis |
| Checklist de custos invisíveis (chips) | J1 · O1 | Grátis |
| Regimes BR (MEI/CPF/Simples) + modo intl, em linguagem humana | O3 | Grátis |
| **A Divisão** (Lucro/Reserva/Custos) em todas as telas | O1 | Grátis |
| **Reserva por pagamento** (caminho de ouro) | J2 · O2 | Grátis |
| Simulador de projeto + aviso comparativo | J3 · O5 | Grátis |
| Detalhamento "como cheguei" + edição inline | confiança | Grátis |
| 1 perfil · 100% offline · sem cadastro | O4 | Grátis |
| **Backup/exportar dados** | O7 | Grátis |
| Banner AdMob discreto (fora do caminho crítico) | — | Grátis |

**Requisitos inegociáveis do MVP** (regras da casa, [04](04-DIFERENCIAIS-E-REGRAS.md)):
estabilidade (R1), preço transparente (R2), sem cadastro (R3), não imitar gov (R4), tabelas
fiscais validadas na Receita (R5), anúncio nunca sobre número (R6), default digno (R7).

---

## 3. v1.1 / Pro — monetização e retenção

| Feature | Oportunidade | Tipo |
|---|---|---|
| Exportar **orçamento em PDF** (com sua marca) | O6 | **Pro** (âncora de conversão) |
| **Vários perfis** (cliente × avulso) | O8 | **Pro** |
| **Modo avançado por regime** (faixas Simples, INSS 11/20%, deduções) | O3 | **Pro** |
| Remover anúncios | — | **Pro** |
| **Lembrete de vencimento/guardar** | O10 | Grátis |
| Módulo **freela pra gringo** (USD, carnê-leão mensal) | O9 | **Pro/nicho** |

---

## 4. v2 — aprofundar o hábito

- **Histórico de reservas** ("quanto já guardei no mês") — O11, fecha o loop de retenção.
- **Alíquota efetiva visível** — O13.
- **Modificadores de preço** (urgência, cliente difícil, revisão) — O14.
- **Auto-recalc** ao mudar um custo/insumo compartilhado — o gancho de retenção que **todos os
  bons apps de precificação têm** (Receitas–Quanto Cobrar, PeqArt). Já parcialmente no
  detalhamento; tornar explícito.

## 5. Futuro (v3+)
- Benchmark de mercado por senioridade/profissão (O12) · comparador antes×depois (O15) ·
  categorias por profissão com defaults de custo · expansão **iOS** (greenfield).

---

## 6. Monetização — o modelo (reconciliado com a evidência)

> **Correção fundamentada:** eu havia proposto "só compra única, sem assinatura". A pesquisa
> de monetização mudou a nuance: **ads sozinho não sustenta** (eCPM BR rende centavos/usuário)
> e o **gatilho mensal da reserva de imposto** é exatamente o que justifica um modelo
> recorrente num utilitário. O que o mercado odeia não é "assinatura" — é **assinatura
> escondida, forçada e revelada tarde** (o crime do TurboTax/MEI Fácil). Então: modelo
> **freemium híbrido, transparente**.

> ⚠️ **CORREÇÃO (19/07/2026) — a âncora de preço abaixo está sob revisão.**
> O Precifica.app (R$ 97,80/ano) é **SaaS de gestão** — o produto que decidimos
> explicitamente NÃO construir. O comparável honesto do que estamos fazendo é
> *Receitas – Quanto Cobrar*: **R$ 12,90–29,90 de compra única**, 100k+
> instalações, 4,73★. Ancorar num SaaS pra vender uma calculadora com memória
> infla o preço em ~4×.
>
> Some-se a isso: o 4,42★ que sustentava a leitura do nicho vem de apps de
> precificação de PRODUTO, não de hora ([ver correção no 00](00-PROPOSTA-DE-PRODUTO.md)).
> Não há dado de willingness-to-pay do nosso público — porque não há amostra do
> nosso público.
>
> **Decisão pendente do dono**, registrada em [08](08-PLANO-OFICIAL.md) §9.

**A estrutura:**
- **Núcleo grátis pra sempre:** calculadora + Divisão + reserva básica **+ o
  primeiro Trabalho salvo**. É o motor de instalação e boca-a-boca na
  comunidade MEI/freela (público massa, Android, orçamento apertado).
- **Pro — o usuário escolhe como pagar** (respeita quem odeia assinatura E quem prefere anual):
  - **Vitalício (compra única): ~R$ 129–149** ⚠️ *sob revisão — ver correção acima*
  - **Anual: ~R$ 89,90/ano** ⚠️ *sob revisão — a âncora usada é de outra categoria*
  - **Mensal: R$ 12,90** (topo do teto de impulso do nicho).
  - *Preços são hipótese a testar — não há dado duro de willingness-to-pay BR ([F](../research/raw/F-mercado-sizing.md)).*
- **Trial curto (3–7 dias)** nas saídas Pro — utilitários convertem melhor com trial curto.
- **Ads = secundário**, não o motor. Banner discreto no grátis; **o Pro é a receita real.**

**Regras de ouro da monetização (anti-★1):**
1. **Preço e o que é Pro aparecem ANTES do usuário investir trabalho** — nunca depois (o crime do TurboTax).
2. **Paywall só nas saídas de alto valor** (PDF, vários perfis, histórico, módulo USD, projeção
   de reserva). **Ver o número básico é sempre grátis.**
3. **Nunca prender dados/atrás de pagamento** — backup e o cálculo básico são livres (o crime do MEI Fácil).
4. **Compra única sempre disponível** — quem não quer assinatura, não assina.

**Por que funciona:** RevenueCat 2025 — utilitários lideram 1ª renovação (58%) e retenção
anual (44% anual vs 17% mensal); a reserva mensal dá o motivo recorrente de voltar. O híbrido
captura tanto o avesso a assinatura (vitalício) quanto o recorrente (anual).

---

## 7. Sinais de sucesso (leves, acionáveis)

- **Conclusão do fluxo guiado** (% que chega ao Resultado) — se cai num passo, ele confunde.
- **Usos de reserva por usuário/mês** — proxy nº1 de hábito/retenção (o coração).
- **% que usa "estimar pra mim"** — mede se o conceito difícil foi resolvido.
- **Conversão Pro por gatilho** (PDF × 2º perfil × módulo USD) — qual recurso puxa a compra.
- **Crash-free sessions** — R1 é feature nº0; monitorar desde o dia 1.

---

## 8. Pré-lançamento (checklist que destrava a Play)

- [ ] **Validar tabelas fiscais na Receita** (DAS/Simples/IRPF/INSS) — bloqueia publicação (R5).
- [ ] Páginas legais (privacidade/termos) no `4yu.com.br/quanto-cobro` — exigência da Play.
- [ ] Título/descrição ASO (`Marca: Calculadora Freela · Quanto Cobrar`) — [01 §3](01-MAPA-DE-OPORTUNIDADES.md).
- [ ] Decisão de **nome** (hoje "decidir depois" — não bloqueia o build, bloqueia a loja).
- [ ] AdMob + RevenueCat configurados (entitlements `pro`, `ad_free`).

---

## 9. Sequência recomendada (depois deste planejamento)

1. **Você valida** este pacote (00–05).
2. Atualizar o **UX Blueprint** com a virada (Divisão como coração; reserva como ouro).
3. **Agente 3 (Design System)** já existe e é maduro → ajustes pontuais de ênfase.
4. **Agente 4 (Flutter)** scaffolda o app seguindo esta IA.
5. Só aí: cores/telas finais, conforme você pediu.

---

*Fim do pacote de planejamento. Índice em [README](README.md).*
