# COPY DECK · Quanto Cobro?

> Documento de redação UX. Cada string abaixo é **final**, pronta pra colar no app.
> Organizado por tela, na ordem em que o usuário vê.
>
> **Voz da marca:** o Sócio que entende de número. Calmo, honesto, parceiro.
> Fala humano, não fiscal. Nunca assusta, nunca finge exatidão.
> (Design System §1.3 e §1.4.)
>
> **Regra da casa (PADRÃO 4YU):** proibido travessão. Nunca. Este documento não
> usa nenhum. Onde a pausa é necessária, use vírgula, ponto, parênteses ou reticências.
>
> **Vocabulário real** (da voz do freelancer, research/D): "quanto cobrar", "freela",
> "cobrei barato", "o Leão", "conta de padaria", "tomei um preju", "merreca", "PIX caiu".
> Preferir esses termos aos formais quando couber.
>
> **Legenda de marcação:**
> - ✅ **NO CÓDIGO** = a string já está assim no app hoje, mantida.
> - ✍️ **SUGESTÃO** = difere do que está no código; recomendação de melhoria (com o "hoje" citado).
> - 🆕 **NOVO** = string ainda não existe no código.

---

## 0. Princípios rápidos (regras de escrita deste app)

1. **Dinheiro é o herói, o rótulo é servo.** Rótulos curtos em CAIXA ALTA; o número domina.
2. **Imposto nunca é ameaça.** "Guardar pro Leão" é segurança, não punição. Nunca "você DEVE".
3. **Erro é do app, não do usuário.** "Coloque um valor pra eu calcular", nunca "input inválido".
4. **Estimativa, sempre honesta.** Todo número de imposto anda com o selo. "Piso", não "verdade".
5. **Fala de gente.** "Como você recebe hoje?", não "Selecione o regime tributário".
6. **R$ sempre formatado** (`R$ 1.234,56`), nunca concatenação. `%` sem espaço (`16%`).

---

## 1. Onboarding (2 telas)

Curto. Fisga a dor, promete privacidade. Não é tutorial.

### Tela 1 de 2 · a dor
- **Título:** `Pare de trabalhar de graça.` ✅ NO CÓDIGO
- **Apoio:** `Descubra quanto cobrar por hora, quanto guardar pro Leão e quanto realmente sobra.` ✍️ SUGESTÃO (hoje: "quanto guardar pro imposto"; "pro Leão" é o vocabulário real e mais quente, sem assustar)
- **Ícone:** `savings`

### Tela 2 de 2 · a confiança
- **Título:** `100% no seu aparelho.` ✅ NO CÓDIGO
- **Apoio:** `Sem cadastro, sem login, sem mandar seus dados pra ninguém. É só abrir e usar, até sem internet.` ✍️ SUGESTÃO (hoje: "mesmo offline"; "até sem internet" é mais humano)
- **Ícone:** `lock`

### Controles do onboarding
- **Pular** (canto superior direito): `Pular` ✅ NO CÓDIGO
- **Botão avançar (tela 1):** `Continuar` ✅ NO CÓDIGO
- **Botão avançar (tela 2, última):** `Começar` ✅ NO CÓDIGO
- **Rodapé de marca:** `Quanto Cobro? · by 4YU` ✍️ SUGESTÃO (hoje mostra "Quanto Cobro? · 4YU"; a assinatura da casa é "by 4YU")

---

## 2. Painel (hub) · 3 estados

AppBar: `Quanto Cobro?` ✅ NO CÓDIGO
Ícone de ação: tooltip `Configurações` ✅ NO CÓDIGO

### 2.1 Estado vazio (primeiro uso)
- **Título-fisga:** `Você provavelmente cobra menos do que deveria.` ✅ NO CÓDIGO
- **Apoio:** `Descubra seu valor-hora justo em 5 perguntas.` ✅ NO CÓDIGO
- **CTA:** `Começar` ✅ NO CÓDIGO
- **Rodapé de confiança:** `Leva 2 minutos · 100% offline` ✅ NO CÓDIGO (ícone `lock`)

### 2.2 Estado de erro (cálculo salvo não abriu)
- **Título:** `Não consegui carregar seu cálculo.` 🆕 NOVO (hoje só mostra a `message` genérica; dar título fixo humano)
- **Apoio:** `Seus dados podem ter se perdido. Vamos refazer, é rápido.` 🆕 NOVO
- **CTA:** `Refazer meu cálculo` ✍️ SUGESTÃO (hoje: "Começar"; "Refazer" é mais honesto porque já existia algo)

### 2.3 Estado pronto (com cálculo)
- **Rótulo do herói:** `SEU VALOR-HORA` ✅ NO CÓDIGO
- **Número-herói:** `R$ 92 /hora` (valor formatado) ✅ NO CÓDIGO
- **Linha de contexto:** `pra ganhar R$ 5.000/mês no seu bolso` ✍️ SUGESTÃO (hoje: "pra ganhar R$ 5.000/mês"; "no seu bolso" reforça que é o líquido, não faturamento)
- **Botão tool 1:** `Recebi um pagamento` ✅ NO CÓDIGO (ícone `payments`)
- **Botão tool 2:** `Vou orçar um projeto` ✅ NO CÓDIGO (ícone `request_quote`)
- **Rótulo da Divisão:** `DE CADA MÊS, PRA ONDE VAI` ✍️ SUGESTÃO (hoje: "DE CADA MÊS"; deixa claro que a barra mostra o destino do dinheiro)
- **Linha de reserva:** `Reserve ~16% de cada PIX que cair (regime: MEI).` ✍️ SUGESTÃO (hoje: "de cada pagamento"; "PIX que cair" é o vocabulário real do momento de uso)
- **Link detalhamento:** `Ver como cheguei` ✅ NO CÓDIGO (ícone `receipt_long`)
- **Botão recalcular:** `Recalcular` ✅ NO CÓDIGO (ícone `calculate`)
- **Selo (rodapé):** `Estimativa de planejamento, não é consultoria fiscal.` ✅ NO CÓDIGO

### 2.4 Faixa de ano defasado (quando a base tributária é de ano anterior)
- **Faixa discreta abaixo do herói:** `Valores base de 2025. Confirme as alíquotas atuais.` 🆕 NOVO (azul calmo `stale`, nunca alarme; hoje não existe no código)

### 2.5 Banner de anúncio (rodapé, só quando há espaço)
- **Rótulo do container:** `Publicidade` 🆕 NOVO (labelSmall, discreto; nunca sobre um número)

---

## 3. Calculadora guiada (5 perguntas)

AppBar (título de passo): `Passo 1 de 5` ... `Passo 5 de 5` ✅ NO CÓDIGO
Botão voltar: ícone `arrow_back`.
Botão primário (passos 1 a 4): `Continuar` ✅ NO CÓDIGO
Botão primário (passo 5): `Ver resultado` ✅ NO CÓDIGO

### P1 · Renda
- **Pergunta-título:** `Quanto você quer GANHAR por mês?` ✅ NO CÓDIGO
- **Campo:** prefixo `R$ `
- **Helper (ⓘ):** `É o que você quer que sobre pra você, não o faturamento.` ✅ NO CÓDIGO
- **Erro (renda 0/vazia):** `Coloque quanto você quer ganhar pra eu calcular.` ✅ NO CÓDIGO

### P2 · Horas faturáveis
- **Pergunta-título:** `Quantas horas você realmente FATURA por mês?` ✅ NO CÓDIGO
- **Campo:** sufixo `h/mês`
- **Helper de erro comum (⚠, âmbar calmo):** `Não são 160h. Tire férias, feriados e o tempo sem cliente (venda, e-mail, estudo). Quase ninguém fatura mais que ~70%.` ✅ NO CÓDIGO
- **Ação secundária:** `Não sei, estimar pra mim` ✅ NO CÓDIGO (ícone `auto_awesome`)
- **Erro (horas 0):** `Preciso de pelo menos 1 hora faturável pra fazer a conta.` ✅ NO CÓDIGO

#### Sheet "estimar pra mim" (horas reais)
- **Título:** `Vamos achar suas horas reais` ✅ NO CÓDIGO
- **Pergunta 1 (label + valor):** `Semanas de férias por ano: 4` ✅ NO CÓDIGO
- **Pergunta 2:** `Do seu tempo, quanto é trabalho pago: 60%` ✅ NO CÓDIGO
- **Pergunta 3:** `Feriados por ano: 12` ✅ NO CÓDIGO
- **Resultado:** `≈ 110 h/mês` ✅ NO CÓDIGO
- **Botão confirmar:** `Usar 110 h/mês` ✅ NO CÓDIGO

### P3 · Custos
- **Pergunta-título:** `Seus custos pra trabalhar?` ✅ NO CÓDIGO
- **Linha de total:** `Total: R$ 850/mês` ✅ NO CÓDIGO
- **Cabeçalho dos chips:** `Não esqueça:` ✅ NO CÓDIGO
- **Chips (rótulo + "+"):** `Contador` · `Coworking` · `Cursos` · `Energia` · `Internet/telefone` · `Equipamento` · `Pró-labore` · `Plano de saúde` · `Software` · `Marketing` · `Transporte` ✅ NO CÓDIGO
- **Tooltip remover custo:** `Remover` ✅ NO CÓDIGO (ícone `close`)
- **Helper novo (opcional, quando lista vazia):** `Todo custo que você paga pra trabalhar entra aqui. O que a conta de padaria esquece.` 🆕 NOVO (usa o termo real "conta de padaria")

### P4 · Regime
- **Pergunta-título:** `Como você recebe hoje?` ✅ NO CÓDIGO
- **Opção 1:** título `Sou MEI` · subtítulo `DAS fixo mensal, imposto baixo` ✅ NO CÓDIGO
- **Opção 2:** título `Autônomo (CPF)` · subtítulo `Carnê-leão + INSS` ✅ NO CÓDIGO
- **Opção 3:** título `Tenho empresa no Simples` · subtítulo `Alíquota por faixa` ✅ NO CÓDIGO
- **Opção 4:** título `Não sei / cliente no exterior` · subtítulo `Reserva padrão de 25% a 30%` ✅ NO CÓDIGO

### P5 · Provisão
- **Pergunta-título:** `Quer provisionar férias e 13º?` ✅ NO CÓDIGO
- **Apoio:** `Autônomo não ganha de graça.` ✅ NO CÓDIGO
- **Toggle ligado:** `Sim, reservar R$ 420/mês` ✅ NO CÓDIGO
- **Toggle desligado:** `Agora não` ✅ NO CÓDIGO

---

## 4. Resultado (as 3 respostas)

AppBar: `Seu resultado` ✅ NO CÓDIGO

- **Bloco 1 rótulo:** `COBRE POR HORA` ✅ NO CÓDIGO
- **Bloco 1 valor (herói):** `R$ 92 /hora` ✅ NO CÓDIGO
- **Equivalência:** `≈ R$ 736/dia · R$ 10.100/mês faturados` ✅ NO CÓDIGO
- **Bloco 2 rótulo:** `DE CADA PAGAMENTO, RESERVE` ✅ NO CÓDIGO
- **Bloco 2 valor:** `16%` ✅ NO CÓDIGO
- **Bloco 3 rótulo:** `LUCRO REAL ESTIMADO` ✅ NO CÓDIGO
- **Bloco 3 valor:** `R$ 5.000/mês` ✅ NO CÓDIGO
- **Aviso "custo maior que meta":** `Seu custo está maior que sua meta. Reveja os custos ou a renda desejada.` ✅ NO CÓDIGO (âmbar `alerta`, nunca vermelho)
- **Botão salvar:** `Salvar este perfil` ✅ NO CÓDIGO
- **Link detalhamento:** `Ver detalhamento` ✅ NO CÓDIGO
- **Selo:** `Estimativa de planejamento, não é consultoria fiscal.` ✅ NO CÓDIGO
- **Snackbar ao salvar:** `Perfil salvo` ✅ NO CÓDIGO
- **Enquadramento (opcional, abaixo do bloco 1):** `Esse é o seu piso. Abaixo disso, você tá se pagando de menos.` 🆕 NOVO (responde à objeção real "custo de vida não é preço"; posiciona como chão, não verdade absoluta)

### Estado degradado (chegou sem dados do cálculo)
- **Mensagem:** `Não recebi os dados do cálculo. Vamos refazer?` ✅ NO CÓDIGO
- **CTA:** `Refazer cálculo` ✅ NO CÓDIGO

---

## 5. Detalhamento ("como cheguei aqui")

AppBar: `Como cheguei nesse número` ✅ NO CÓDIGO

Tabela linha a linha (rótulo à esquerda, valor `tnum` à direita):
- `Renda desejada` · `R$ 5.000` ✅ NO CÓDIGO
- `+ Custos fixos` · `R$ 850` ✅ NO CÓDIGO
- `+ Provisão férias/13º` · `R$ 420` (só se ligado) ✅ NO CÓDIGO
- `+ Imposto estimado (16%)` · `R$ 1.480` ✅ NO CÓDIGO
- `= Preciso faturar` · `R$ 10.100` (forte) ✅ NO CÓDIGO
- `÷ Horas faturáveis` · `110 h` ✅ NO CÓDIGO
- `= Valor-hora` · `R$ 92/h` (forte) ✅ NO CÓDIGO
- **Botão editar:** `Editar meu cálculo` ✅ NO CÓDIGO (ícone `edit`)
- **Selo:** `Estimativa de planejamento, não é consultoria fiscal.` ✅ NO CÓDIGO

### Estado sem cálculo salvo
- **Mensagem:** `Você ainda não tem um cálculo salvo.` ✅ NO CÓDIGO
- **CTA:** `Fazer meu cálculo` ✅ NO CÓDIGO

---

## 6. Reserva (tool recorrente, o caminho de ouro)

AppBar: `Recebi um pagamento` ✅ NO CÓDIGO

- **Rótulo do campo:** `Quanto você recebeu?` ✅ NO CÓDIGO
- **Campo:** prefixo `R$ `, autofoco
- **Rótulo regime:** `Regime:` ✅ NO CÓDIGO (dropdown com tags: `MEI` · `Autônomo` · `Simples` · `Internacional`)
- **Estado vazio (sem valor):** `Digite o valor que caiu pra ver quanto guardar.` ✍️ SUGESTÃO (hoje: "o valor recebido"; "que caiu" espelha o PIX que caiu)
- **Rótulo do resultado (herói):** `RESERVE PRO LEÃO` ✍️ SUGESTÃO (hoje: "RESERVE PARA IMPOSTO"; "pro Leão" é o termo real e mais leve, e o selo abaixo já diz "imposto/planejamento")
- **Valor-herói:** `R$ 320` ✅ NO CÓDIGO (cor `reserva`, azul-cofre)
- **Linha "sobra":** `Sobra pra usar: R$ 1.680` ✅ NO CÓDIGO
- **Linha de contexto:** `16% do que entrou é do Leão, o resto é seu.` ✍️ SUGESTÃO (hoje: "do leão" minúsculo; padronizar "Leão" maiúsculo como personagem)
- **Legenda da barra:** `Reserva R$ 320` · `Sobra R$ 1.680` ✅ NO CÓDIGO
- **Selo curto:** `Estimativa pra te ajudar a decidir.` ✅ NO CÓDIGO

---

## 7. Simulador ("vou orçar um projeto")

AppBar: `Vou orçar um projeto` ✅ NO CÓDIGO

- **Campo 1:** `Valor do projeto` (prefixo `R$ `) ✅ NO CÓDIGO
- **Campo 2:** `Horas estimadas` (sufixo `h`) ✅ NO CÓDIGO
- **Campo 3:** `Custos do projeto (opcional)` (prefixo `R$ `) ✅ NO CÓDIGO
- **Estado vazio:** `Preencha valor e horas pra ver o lucro real.` ✅ NO CÓDIGO
- **Rótulo do resultado (herói):** `LUCRO REAL` ✅ NO CÓDIGO (cor `lucro`, verde)
- **Valor-herói:** `R$ 1.950` ✅ NO CÓDIGO
- **Linha de contexto:** `Valor-hora efetivo: R$ 65/h` ✅ NO CÓDIGO
- **Selo curto:** `Estimativa pra te ajudar a decidir.` ✅ NO CÓDIGO

### 7.1 Aviso comparativo "abaixo do alvo" (o app que te defende)
- **Título do aviso (⚠ `trending_down`):** `Abaixo do seu alvo (R$ 92/h).` ✅ NO CÓDIGO
- **Sugestão:** `Cobre ~R$ 4.260 pra manter seu lucro.` ✅ NO CÓDIGO
- **Botão aplicar:** `Usar R$ 4.260` ✅ NO CÓDIGO
- **Variante forte (opcional, quando muito abaixo):** `Bem abaixo do seu alvo. Nesse preço, você quase trabalha de graça.` 🆕 NOVO (âmbar, não vermelho; usa a promessa da marca sem assustar)

---

## 8. Perfis (Pro)

AppBar: `Perfis` ✅ NO CÓDIGO

- **Card do perfil atual:** título = nome do perfil · subtítulo `R$ 92/h` ✅ NO CÓDIGO
- **Card sem perfil (título):** `Você ainda não tem um perfil` ✅ NO CÓDIGO
- **Card sem perfil (apoio):** `Faça seu primeiro cálculo` ✅ NO CÓDIGO
- **Card de upsell (título):** `Vários perfis` ✅ NO CÓDIGO
- **Card de upsell (apoio):** `Preço muda por tipo de cliente? Tenha um perfil pra cada cenário.` ✅ NO CÓDIGO
- **Nota (Pro já ativo):** `Recurso Pro liberado. Múltiplos perfis chegam numa próxima versão.` ✅ NO CÓDIGO
- **CTA (não Pro):** `Conhecer o Pro` ✅ NO CÓDIGO

---

## 9. Configurações

AppBar: `Configurações` ✅ NO CÓDIGO

### Aparência
- **Cabeçalho:** `Aparência` ✅ NO CÓDIGO
- **Segmentos:** `Escuro` · `Claro` · `Sistema` ✅ NO CÓDIGO

### Pro e perfis
- **Item Pro (não ativo):** `Conhecer o Pro` ✅ NO CÓDIGO
- **Item Pro (ativo):** `Pro ativo` ✅ NO CÓDIGO
- **Item perfis (título):** `Perfis` ✅ NO CÓDIGO
- **Item perfis (apoio):** `Cenários de preço por tipo de cliente` ✅ NO CÓDIGO

### Seus dados
- **Cabeçalho:** `Seus dados` ✅ NO CÓDIGO
- **Exportar (título):** `Exportar dados (backup)` ✅ NO CÓDIGO
- **Exportar (apoio):** `Copie e guarde onde quiser. Sem nuvem, sem conta.` ✅ NO CÓDIGO
- **Restaurar (título):** `Restaurar backup` ✅ NO CÓDIGO
- **Apagar (título):** `Apagar meus dados` ✅ NO CÓDIGO

### Diálogo exportar
- **Título:** `Backup dos seus dados` ✅ NO CÓDIGO
- **Botão copiar:** `Copiar` ✅ NO CÓDIGO
- **Botão fechar:** `Fechar` ✅ NO CÓDIGO
- **Snackbar:** `Backup copiado` ✅ NO CÓDIGO
- **Sem dados pra exportar (snackbar):** `Ainda não há um cálculo pra exportar.` ✅ NO CÓDIGO

### Diálogo restaurar
- **Título:** `Restaurar backup` ✅ NO CÓDIGO
- **Placeholder do campo:** `Cole aqui o texto do seu backup` ✅ NO CÓDIGO
- **Botão cancelar:** `Cancelar` ✅ NO CÓDIGO
- **Botão confirmar:** `Restaurar` ✅ NO CÓDIGO
- **Snackbar sucesso:** `Backup restaurado` ✅ NO CÓDIGO
- **Erro (backup inválido):** `Não consegui ler esse backup. Confere se o texto foi colado inteiro.` ✍️ SUGESTÃO (hoje: "Não consegui ler esse backup."; a segunda frase orienta a correção sem culpar)

### Diálogo apagar (confirmação destrutiva)
- **Título:** `Apagar meus dados?` ✅ NO CÓDIGO
- **Corpo:** `Isso remove seu cálculo do aparelho. Não dá pra desfazer.` ✅ NO CÓDIGO
- **Botão cancelar:** `Cancelar` ✅ NO CÓDIGO
- **Botão apagar (carmim):** `Apagar` ✅ NO CÓDIGO
- **Snackbar:** `Dados apagados` ✅ NO CÓDIGO

### Telemetria e legal
- **Telemetria (título):** `Ajudar a melhorar o app` ✅ NO CÓDIGO
- **Telemetria (apoio):** `Envia só métricas anônimas de uso e estabilidade. Nunca sua renda.` ✅ NO CÓDIGO
- **Legal (item):** `Privacidade e Termos` ✅ NO CÓDIGO

### Sobre
- **Cabeçalho:** `Sobre` ✅ NO CÓDIGO
- **Versão:** `Quanto Cobro? · versão 0.1.0` ✅ NO CÓDIGO
- **Assinatura:** `by 4YU · sac@4yu.com.br` ✍️ SUGESTÃO (hoje: "por 4YU · ..."; "by 4YU" é o selo padrão da casa, aqui é o lugar certo dele)

---

## 10. Pro (compra única + planos)

AppBar: `Pro` ✅ NO CÓDIGO

### Cabeçalho (não Pro)
- **Título:** `Faça mais com o Pro` ✅ NO CÓDIGO
- **Apoio:** `O cálculo, a reserva e o simulador são grátis pra sempre.` ✅ NO CÓDIGO

### Benefícios
- `Exportar orçamento em PDF com sua marca` ✅ NO CÓDIGO (ícone `picture_as_pdf`)
- `Vários perfis (cliente recorrente x avulso)` ✅ NO CÓDIGO (ícone `switch_account`)
- `Modo avançado por regime (faixas do Simples, INSS, deduções)` ✅ NO CÓDIGO (ícone `tune`)
- `Módulo freela pra gringo (USD, carnê-leão mensal)` ✅ NO CÓDIGO (ícone `public`)
- `Remover anúncios` ✅ NO CÓDIGO (ícone `block`)

### Preços e CTAs
- **Plano 1 (destaque):** título `Vitalício (sem assinatura)` · valor `R$ 129, uma vez só` · CTA `Comprar` ✅ NO CÓDIGO
- **Plano 2:** título `Anual` · valor `R$ 89,90/ano` · CTA `Assinar` ✅ NO CÓDIGO
- **Plano 3:** título `Mensal` · valor `R$ 12,90/mês` · CTA `Assinar` ✅ NO CÓDIGO
- **Nota de preço provisório:** `Preços provisórios. O pagamento real liga com a loja; por ora o Pro é ativado localmente pra você testar.` ✍️ SUGESTÃO (hoje tem duas frases mais longas; enxugado, mesma honestidade)
- **Restaurar:** `Restaurar compras` ✅ NO CÓDIGO
- **Snackbar (nada a restaurar):** `Nada a restaurar por enquanto.` ✅ NO CÓDIGO
- **Snackbar (Pro ativado):** `Pro ativado` ✅ NO CÓDIGO

### Estado Pro ativo
- **Título:** `Pro ativo` ✅ NO CÓDIGO
- **Apoio:** `Valeu! Todos os recursos Pro estão liberados.` ✍️ SUGESTÃO (hoje: "Obrigado!"; "Valeu!" é mais próximo do tom parceiro)
- **Botão:** `Voltar` ✅ NO CÓDIGO

### Gatilhos de Pro (aparecem no momento de valor, não como pop-up)
- **Ao tocar exportar PDF:** `Exportar orçamento em PDF é recurso Pro.` 🆕 NOVO
- **Ao criar 2º perfil:** `Vários perfis é recurso Pro.` 🆕 NOVO
- **Ao abrir modo avançado:** `Modo avançado por regime é recurso Pro.` 🆕 NOVO

---

## 11. Componentes transversais

### Selo de estimativa (onipresente, calmo, nunca vermelho)
- **Completo:** `Estimativa de planejamento, não é consultoria fiscal.` ✅ NO CÓDIGO
- **Curto (tools):** `Estimativa pra te ajudar a decidir.` ✅ NO CÓDIGO

### Faixa de ano defasado (azul calmo, informação)
- `Valores base de 2025. Confirme as alíquotas atuais.` 🆕 NOVO

### Snackbars (catálogo)
- `Perfil salvo` ✅ NO CÓDIGO
- `Perfil removido` + ação `Desfazer` 🆕 NOVO (para quando houver remoção de perfil, Pro)
- `Dados apagados` ✅ NO CÓDIGO
- `Backup copiado` ✅ NO CÓDIGO
- `Backup restaurado` ✅ NO CÓDIGO
- `Pro ativado` ✅ NO CÓDIGO
- **Falha ao salvar:** `Não consegui salvar. Tenta de novo.` + ação `Desfazer` 🆕 NOVO

### Tooltips e ícones-ação (labels de acessibilidade / TalkBack)
- Configurações: `Configurações` ✅ NO CÓDIGO
- Voltar: `Voltar`
- Recebi pagamento: `Recebi um pagamento`
- Orçar projeto: `Vou orçar um projeto`
- Ver como cheguei: `Ver como cheguei`
- Recalcular: `Recalcular`
- Remover custo: `Remover` ✅ NO CÓDIGO
- Estimar horas: `Estimar minhas horas`

### Labels de botão (biblioteca)
`Começar` · `Continuar` · `Ver resultado` · `Recalcular` · `Salvar este perfil` · `Ver como cheguei` · `Ver detalhamento` · `Editar meu cálculo` · `Refazer cálculo` · `Não sei, estimar pra mim` · `Conhecer o Pro` · `Comprar` · `Assinar` · `Restaurar compras` · `Copiar` · `Restaurar` · `Cancelar` · `Apagar` · `Fechar` · `Desfazer`.

---

## 12. Catálogo de erros (todos, com copy humana)

| Situação | Copy | Marcação |
|---|---|---|
| Renda 0 ou vazia | `Coloque quanto você quer ganhar pra eu calcular.` | ✅ NO CÓDIGO |
| Horas 0 | `Preciso de pelo menos 1 hora faturável pra fazer a conta.` | ✅ NO CÓDIGO |
| Custo maior que a meta | `Seu custo está maior que sua meta. Reveja os custos ou a renda desejada.` | ✅ NO CÓDIGO |
| Cálculo salvo não abriu (Painel) | `Não consegui carregar seu cálculo.` + `Seus dados podem ter se perdido. Vamos refazer, é rápido.` | 🆕 NOVO |
| Resultado sem dados | `Não recebi os dados do cálculo. Vamos refazer?` | ✅ NO CÓDIGO |
| Detalhamento sem cálculo | `Você ainda não tem um cálculo salvo.` | ✅ NO CÓDIGO |
| Backup inválido ao restaurar | `Não consegui ler esse backup. Confere se o texto foi colado inteiro.` | ✍️ SUGESTÃO |
| Nada pra exportar | `Ainda não há um cálculo pra exportar.` | ✅ NO CÓDIGO |
| Falha ao salvar | `Não consegui salvar. Tenta de novo.` + `Desfazer` | 🆕 NOVO |
| Nada a restaurar (compras) | `Nada a restaurar por enquanto.` | ✅ NO CÓDIGO |

> Regra: nenhum erro usa "inválido", "erro:", código ou tom de bronca. O app assume a falha ("não consegui"), nunca acusa o usuário.

---

## 13. Legal (resumo mostrado no app)

> Texto-fonte já existe em `legal_texts.dart` (rascunho a validar juridicamente).
> Ajuste de voz sugerido no primeiro parágrafo dos Termos:

- ✍️ SUGESTÃO (Termos, abertura): `Os números do app são estimativas pra te ajudar a decidir preço. Não são consultoria fiscal nem declaração de imposto.` (hoje: "ESTIMATIVAS DE PLANEJAMENTO para ajudar você a decidir preço"; versão mais falada, mesma substância).

---

## 14. ASO / Loja (Play Store)

> Vocabulário puxado da voz real (research/D): "quanto cobrar", "freela", "valor da hora", "o Leão", "imposto", "reserva". Sem cheiro de IA, linguagem seca e específica (objeção 6 da research).

### Título curto (≤ 30 caracteres)
`Quanto Cobro? Freela e Leão` (27 caracteres) 🆕 NOVO

> Alternativas dentro do limite:
> - `Quanto Cobro? Valor da hora` (27)
> - `Quanto Cobro? Preço de freela` (29)

### Descrição curta (≤ 80 caracteres)
`Seu valor-hora justo, quanto guardar pro Leão e quanto sobra. Offline.` (69 caracteres) 🆕 NOVO

> Alternativa: `Pare de trabalhar de graça. Valor-hora, imposto e lucro do freela.` (65)

### Descrição longa (5 linhas)
🆕 NOVO

```
Você provavelmente cobra menos do que deveria. Descubra seu valor-hora justo em 5 perguntas, sem planilha e sem chute.

A cada PIX que cai, veja na hora quanto é seu, quanto é do Leão e quanto foi custo. A mesma leitura, sempre: Lucro, Reserva e Custos, repartidos com honestidade.

Vai orçar um projeto? O simulador diz se aquele valor dá lucro real e te avisa quando o preço tá baixo demais. É o sócio que te defende de trabalhar de graça.

Contexto brasileiro feito de gente: MEI, autônomo (CPF), Simples ou cliente no exterior. A conta do imposto acontece nos bastidores, você só responde como recebe.

100% no seu aparelho. Sem cadastro, sem login, sem enviar seus dados. Funciona offline. É estimativa de planejamento pra você decidir o preço, não consultoria fiscal.
```

---

## 15. Resumo das divergências código vs. copy (checklist de aplicação)

Itens ✍️ SUGESTÃO e 🆕 NOVO que valem virar tarefa de código:

**Ajustes de voz (SUGESTÃO):**
1. Onboarding tela 1: "pro imposto" → `pro Leão`.
2. Onboarding tela 2: "mesmo offline" → `até sem internet`.
3. Onboarding rodapé e Sobre: "4YU" / "por 4YU" → `by 4YU`.
4. Painel herói: adicionar `no seu bolso` à linha de contexto.
5. Painel rótulo da Divisão: "DE CADA MÊS" → `DE CADA MÊS, PRA ONDE VAI`.
6. Painel linha de reserva: "de cada pagamento" → `de cada PIX que cair`.
7. Painel erro: título fixo `Não consegui carregar seu cálculo.` + apoio, e CTA `Refazer meu cálculo`.
8. Reserva estado vazio: "o valor recebido" → `o valor que caiu`.
9. Reserva rótulo herói: "RESERVE PARA IMPOSTO" → `RESERVE PRO LEÃO`.
10. Reserva contexto: padronizar `Leão` maiúsculo.
11. Config erro de backup: acrescentar `Confere se o texto foi colado inteiro.`
12. Pro estado ativo: "Obrigado!" → `Valeu!`; nota de preço enxugada.

**Strings novas (NOVO):**
13. Faixa de ano defasado (`Valores base de 2025...`) no Painel/Resultado/Reserva.
14. Rótulo `Publicidade` no banner.
15. Gatilhos de Pro contextuais (PDF, 2º perfil, modo avançado).
16. Enquadramento "piso" no Resultado (responde à objeção de mercado).
17. Snackbars de falha ao salvar e remoção de perfil com `Desfazer`.
18. Variante forte do aviso "abaixo do alvo".
19. Metadados ASO (título curto, descrição curta, descrição longa).

---

*Copy Deck "Quanto Cobro?" · voz "o Sócio que entende de número" · PT-BR · sem travessão (PADRÃO 4YU). Base: Design-System §1.3/§1.4, planning/02 e 04, research/D. Cada string é final, pronta pra colar.*
