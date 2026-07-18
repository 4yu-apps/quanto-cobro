# Quanto Cobro? — Arquitetura de Informação (o "sitemap" do app)

> A estrutura de telas: quais são as páginas, o que tem em cada uma, qual o objetivo do
> usuário e o que ele pode fazer ali. É o equivalente ao sitemap de um site, para app.
> **Sem decisões de cor/layout** — isso vem depois. Base: protótipo atual (9 telas) +
> [proposta](00-PROPOSTA-DE-PRODUTO.md) (Divisão como coração) + [evidência](../research/ANALISE-QUANTITATIVA-REVIEWS.md).

---

## 1. Modelo de navegação: hub-and-spoke centrado no Painel

Tudo orbita **uma tela — o Painel**. Sem abas profundas (profundidade = fricção em app
utilitário). O Painel mostra as respostas de relance e dá atalho de 1 toque para os jobs
recorrentes. A calculadora longa é um **satélite** (fluxo guiado), não a casa.

```
                          ┌─────────────────────────────┐
   [1º uso] ── ONBOARDING ─┤          PAINEL (hub)       ├─ CONFIGURAÇÕES
                          │  Divisão + 3 respostas +     │     └─ Backup / Apagar / Tema
                          │  atalhos recorrentes         │
                          └──┬─────┬─────┬─────┬─────┬───┘
                             │     │     │     │     │
              CALCULADORA ◄──┘     │     │     │     └──► PERFIS (Pro)
              (5 passos)           │     │     │
                 └─► RESULTADO     │     │     └──► DETALHAMENTO ("como cheguei")
                       └─► salva   │     │
                                   │     └──► SIMULADOR de projeto  (J3)
                                   └──► RESERVA por pagamento       (J2 · ouro)
                                            └─► HISTÓRICO (v2)

   [gatilho de valor] ──► TELA PRO (compra única)
```

**Grupos de tela:**
- **Hub:** Painel (+ estado vazio / onboarding).
- **Estratégico (raro):** Calculadora guiada → Resultado → Detalhamento.
- **Operacional (recorrente — o motor):** Reserva · Simulador.
- **Gestão:** Perfis (Pro) · Configurações · Tela Pro.

> **Por que não bottom-nav de abas?** As 3 respostas convivem no Painel e os tools são ações
> rápidas, não destinos onde se "mora". Hub mantém o app simples (trade-off registrado no
> blueprint §15). Reavaliar só se o v2 crescer (histórico, lembretes).

---

## 2. Inventário de telas

Para cada uma: **objetivo · o que o usuário quer · o que tem · o que ele pode fazer · estados**.

### 2.1 ⭐ Painel (Home) — o hub
- **Objetivo:** mostrar de relance "quanto cobrar, quanto guardar, quanto sobra" e dar 1 toque
  para os jobs recorrentes.
- **Usuário quer:** "me diz rápido como está meu dinheiro / o que faço agora."
- **Tem:** card-herói do valor-hora · **a Divisão** (Lucro/Reserva/Custos) · **2 botões grandes:
  "Recebi um pagamento" e "Vou orçar um projeto"** · resumo (reserva %, lucro real, custos) ·
  "ver como cheguei" · Recalcular · acesso a Configurações · banner AdMob (rodapé, só se couber).
- **Pode fazer:** ir pra Reserva (C2), Simulador (C3), Detalhamento (C6), Recalcular (C4),
  Configurações, Perfis.
- **Estados:** com cálculo (padrão) · **vazio/primeiro uso** (§2.2) · regime desatualizado
  (faixa calma "valores base de 2025").
- **Mudança da proposta:** dar à Divisão + "Recebi um pagamento" peso ≥ ao card do valor-hora
  (o recorrente é o que retém).

### 2.2 Estado vazio / primeiro uso
- **Objetivo:** transformar o vazio em "começar", sem assustar.
- **Usuário quer:** entender em 3s o que ganha aqui.
- **Tem:** título-fisga *"Você provavelmente cobra menos do que deveria."* · apoio *"Descubra
  seu valor-hora justo em 5 perguntas."* · 1 CTA *"Começar"* · selo *"2 minutos · 100% offline"*.
- **Pode fazer:** iniciar a Calculadora.

### 2.3 Onboarding (2–3 telas, primeira abertura)
- **Objetivo:** fisgar a dor + escolher modo (BR/internacional) + prometer privacidade.
- **Usuário quer:** saber que veio ao lugar certo e que é rápido/seguro.
- **Tem:** a dor ("pare de trabalhar de graça") · escolha BR × internacional · "100% offline,
  sem cadastro". Curto — não é tutorial.
- **Pode fazer:** seguir pra Calculadora (setup do valor-hora).

### 2.4 Calculadora guiada (5 passos) — setup estratégico (J1)
- **Objetivo:** chegar nas 3 respostas sem assustar — uma pergunta por tela, cada uma com
  default e um momento didático.
- **Usuário quer:** um número digno sem preencher planilha.
- **Tem (1 pergunta/tela):** P1 Renda desejada (no bolso) · P2 **Horas faturáveis** (+ helper
  "estimar pra mim") · P3 Custos fixos (+ chips dos esquecidos) · P4 "Como você recebe hoje?"
  (regime sem jargão) · P5 Férias/13º (opcional). Stepper ●●○○○.
- **Pode fazer:** avançar com defaults ("continuar, continuar"), pedir "estimar pra mim",
  voltar, abrir modo avançado (Pro) no regime.
- **Estados:** por passo — vazio (default), erro humano (renda 0, horas 0 = divisão por zero).

### 2.5 Resultado (as 3 respostas)
- **Objetivo:** entregar valor-hora + reserva % + lucro real com hierarquia clara e caminho
  para confiar.
- **Usuário quer:** "então é isso que eu cobro? posso confiar?"
- **Tem:** herói *COBRE POR HORA* · *DE CADA PAGAMENTO, RESERVE* · *LUCRO REAL ESTIMADO* ·
  **a Divisão** (destaque no Lucro) · equivalências (dia/mês) · "ver detalhamento" · "salvar
  perfil" · **selo de estimativa** · (Pro) exportar PDF.
- **Pode fazer:** salvar perfil (→ Painel), abrir detalhamento, exportar PDF (gatilho Pro).

### 2.6 Detalhamento ("como cheguei aqui")
- **Objetivo:** abrir a caixa-preta — a conta linha a linha, editável.
- **Usuário quer:** confiar no número e ajustar um item sem refazer tudo.
- **Tem:** tabela `Renda + Custos + Provisão + Imposto = Faturamento ÷ Horas = Valor-hora`,
  cada item **editável inline** (recalcula na hora).
- **Pode fazer:** editar qualquer item, voltar. Transparência = confiança (app de dinheiro).

### 2.7 ⭐ Reserva por pagamento (J2) — o caminho de ouro
- **Objetivo:** em segundos, dizer quanto guardar de um pagamento que acabou de cair.
- **Usuário quer:** "isso é meu ou é do leão?"
- **Tem:** 1 campo (*"Quanto você recebeu?"*) · **herói: RESERVE PARA IMPOSTO** · "Sobra pra
  usar" · **Divisão** com destaque na Reserva · regime herdado do perfil (editável) · selo.
- **Pode fazer:** digitar valor (resultado ao vivo), trocar regime pontual, (v2) salvar no
  histórico.
- **Por quê:** é o uso recorrente que constrói hábito. **2 toques do Painel.** É a régua de
  retenção do produto inteiro.

### 2.8 Simulador de projeto (J3)
- **Objetivo:** dizer se um valor de projeto dá lucro real — e ligar de volta ao valor-hora alvo.
- **Usuário quer:** "aceito esse projeto ou tô me sabotando?"
- **Tem:** valor + horas + custos do projeto · **herói: LUCRO REAL** · valor-hora efetivo ·
  **aviso comparativo** quando abaixo do alvo, com preço sugerido · Divisão (destaque no Lucro).
- **Pode fazer:** simular ao vivo, aplicar preço sugerido, (Pro) exportar orçamento em PDF.
- **Diferencial:** o **aviso** ("abaixo do seu alvo, cobre ~R$ X") — o app **defende** o usuário.

### 2.9 Perfis (Pro)
- **Objetivo:** alternar entre cenários de preço (cliente recorrente × avulso × outro nicho).
- **Usuário quer:** "meu preço muda por tipo de cliente."
- **Tem:** lista de perfis com valor-hora · "+ novo" · nota "vários perfis é Pro".
- **Pode fazer:** criar/selecionar/renomear perfil (Pro). Muda o Painel inteiro.

### 2.10 Configurações
- **Objetivo:** controle e confiança.
- **Usuário quer:** ajustar moeda/tema, e sentir que manda nos próprios dados.
- **Tem:** moeda/modo (BR×intl) · tema (escuro/claro) · **backup/exportar dados** · **apagar
  meus dados** (confirmação dupla) · restaurar compras · ano das tabelas · Sobre/by 4YU · links
  legais (privacidade/termos — para a Play).
- **Pode fazer:** trocar tema, exportar/limpar dados, restaurar Pro.
- **Novo (pedido recorrente fase 2):** backup/restore é elevado a item de primeira classe.

### 2.11 Tela Pro (compra única)
- **Objetivo:** converter no **momento de valor**, não como pop-up.
- **Usuário quer:** entender o que ganha, sem se sentir empurrado.
- **Tem:** benefícios (vários perfis · exportar PDF · modo avançado por regime · remover
  anúncios) · **preços transparentes** (vitalício sem assinatura + anual/mensal opcionais,
  conforme o modelo híbrido validado em [05 §6](05-ESCOPO-E-ROADMAP.md)) · CTA · "restaurar
  compras". O núcleo é sempre grátis; o preço aparece antes de qualquer trabalho (anti-★1).
- **Aparece em:** tocar "exportar PDF", criar 2º perfil, abrir "modo avançado".

### 2.12 Histórico de reservas — **v2** (gancho de hábito)
- **Objetivo:** acompanhar quanto já guardou no mês; reforçar o hábito do J2.
- **Usuário quer:** "quanto já separei pro imposto este mês?"
- **Tem:** lista de reservas registradas · total do mês · (futuro) lembrete de guardar.
- **Por quê:** transforma o recorrente em progresso visível — a peça que fecha a retenção.

---

## 3. Sub-componentes de fluxo (não são "páginas", mas telas de apoio)

- **Helper "estimar pra mim"** (sheet): 3 perguntas (férias/ano · % tempo pago · feriados) →
  devolve as horas faturáveis. Resolve o conceito de maior alavanca (P2 da calculadora).
- **Confirmação destrutiva** (dialog): apagar perfil / apagar dados.
- **Snackbar com Desfazer:** salvar/remover perfil, apagar dados.

---

## 4. Mapa job → tela → métrica de sucesso

| Job | Tela(s) | Sinal de sucesso (leve) |
|---|---|---|
| J1 cobrar | Calculadora → Resultado | % que conclui o fluxo (se cair, o passo confunde — suspeito: horas) |
| J2 reservar | **Reserva** (+ Histórico v2) | usos de reserva por usuário/mês (proxy de hábito) |
| J3 lucro projeto | Simulador | usos + % que aplica o preço sugerido |
| confiar | Detalhamento | acessos a "como cheguei" |
| converter | Tela Pro | conversão por gatilho (PDF × 2º perfil × avançado) |

---

## 5. Diferenças vs. o protótipo atual (o que muda de estrutura)

1. **Reequilíbrio do Painel:** Divisão + "Recebi um pagamento" ganham peso; o valor-hora deixa
   de ser o único herói.
2. **Backup/restore** promovido a item de 1ª classe em Configurações (pedido recorrente real).
3. **Histórico de reservas** entra como tela planejada de v2 (fecha o hábito).
4. Todo o resto do inventário (9 telas) **se mantém** — a estrutura estava certa; muda a ênfase.

---

*Próximo: [04 — Diferenciais e regras da casa](04-DIFERENCIAIS-E-REGRAS.md).*
