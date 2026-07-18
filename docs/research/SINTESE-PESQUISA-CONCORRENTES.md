# Quanto Cobro? — Síntese da mineração de concorrentes & demanda

> **Data:** 2026-07-18 · **Método:** 5 frentes de pesquisa em paralelo (apps BR de
> precificação, apps internacionais de rate, apps BR de MEI/imposto, voz real do
> freelancer, ASO/naming). Evidências brutas com URLs em [`raw/`](raw/).
> **Propósito:** confrontar o [UX Blueprint](../UX-Blueprint.md) com evidência real
> antes de qualquer código — o passo "pincelar bastante antes de fazer".

---

## 1. TL;DR (o veredito)

O blueprint **se sustenta bem**. Das 6 teses, 4 saem validadas com força, 1 com
nuance importante e 1 (imposto) validada mas por comunidade, não por review de app.
Três descobertas mudam a ênfase do produto:

1. **O ouro é a ponte que ninguém construiu.** O mercado são três silos que não
   conversam: calculadoras de preço (web, uso único) · apps de DAS/gestão MEI ·
   apps de carnê-leão. Ninguém liga **"quanto cobrar" → "quanto reservar deste
   recebimento" → "não esqueça a guia"**. É exatamente a espinha do blueprint
   (estratégico → operacional). **Esse é o diferencial defensável.**
2. **A calculadora não é o produto — o hábito é.** Lá fora, o melhor app do nicho
   (FreelaCalc, 4.9★) tem só 100+ instalações; calculadora pura não retém nem
   monetiza. O núcleo tem que ser o **tool recorrente** (reserva por pagamento),
   não a conta do valor-hora.
3. **Confiança é um fosso barato.** O mercado está queimado por *cadastro
   obrigatório*, *cobrança-surpresa* e apps que se confundem com o do governo.
   Offline + sem cadastro + preço transparente já é contraste crível e imediato.

**Maior risco:** precisão fiscal. Nunca copiar o "reserve 25–30%" genérico dos
gringos — no BR está errado (um MEI guardaria ~5× demais) e destrói justamente a
credibilidade que é o trunfo.

**Naming:** "Quanto Cobro?" custa ASO e clareza (a busca real é "cobr**ar**", não
"cob**ro**"; e "cobro" ecoa cobrança). Recomendação: **marca própria + subtítulo
com as keywords**, guardando "Quanto Cobro?" como tagline.

---

## 2. As 6 teses do blueprint vs. evidência

| # | Tese | Veredito | Evidência-chave |
|---|------|----------|-----------------|
| 1 | Freelancer cobra de menos por ignorar custos invisíveis | ✅ **Validada (forte)** | Reddit r/brdev verbatim: *"cobrei 6k... meus chefes cobrariam 50k... tomei um puta preju"* (142 upvotes); reviews de apps pedindo espontaneamente depreciação/energia |
| 2 | Não reserva imposto e toma susto com DAS/IR | ✅ **Validada, porém silenciosa** | Reddit: *"descobri que tinha que declarar pelo carnê-leão... paguei os boletos com as multas por atraso"*; push de vencimento do DAS da Receita subiu pagamento em dia **+9%**. **Não aparece em review de app** — a dor vive na comunidade e vem *depois* do susto |
| 3 | Contexto tributário BR é o diferencial | ✅ **Validada (forte)** | Todo gringo ou chuta **25–30% genérico** ou aplica o **sistema US literal** (1099/SE-tax) — inúteis no BR. O único benchmark fiscal profundo do BR é **web** (calculadorabrasil.com.br), sem app/offline |
| 4 | Concorrentes são calculadoras rasas de 1 campo | ⚠️ **Validada com nuance** | Apps mobile são rasos, mas os **web tools gringos ensinam bem** (só genérico/EN); FreelaCalc já tem 4 modelos. **O diferencial não é "mais campos" — é profundidade fiscal + didática + execução (offline/sem ads)** |
| 5 | Retenção via tools recorrentes | ⚠️ **Parcial — refina o foco** | "Simular lucro de projeto" já é **commoditizado**; **"reservar imposto por pagamento" NÃO existe em nenhum concorrente** — é o loop mais defensável. Deve ser o herói, não o coadjuvante |
| 6 | Offline, sem cadastro, privacidade | ✅ **Validada (forte)** | ★1 explícitos por cadastro obrigatório (*"só usa se cadastrar o e-mail pra receber propaganda. Sem chance!"*) e cobrança-surpresa (*"entrou no meu iCloud e faturou no meu cartão"*); "sem propaganda" é elogio recorrente |

---

## 3. O que ENXUGAR e o que ESTENDER (decisão de produto)

### Enxugar / desprioritizar
- **"Mais campos" e "modo avançado por regime" como chamariz.** A evidência diz que
  profundidade fiscal + didática + confiança vendem mais que quantidade de inputs.
  Modo avançado continua sendo bom gancho de Pro, mas **não é a promessa da capa**.
- **Simulador de projeto como diferencial.** Está commoditizado. Mantém no MVP
  (é um dos 3 jobs), mas o *twist* que diferencia é só o **aviso comparativo**
  ("abaixo do seu alvo") — não o cálculo em si.

### Estender / promover
- **Reserva por pagamento vira o NÚCLEO** (não só um dos tools). É a função inédita
  e recorrente — o motor de hábito e o diferencial defensável. Herói do Painel.
- **Alíquota efetiva como resultado visível** (roubado dos gringos, com twist BR):
  *"sua alíquota efetiva como MEI é X%"* — traduz o labirinto num número que ancora.
- **Lembrete de guardar/vencimento** — deixou de ser diferencial e virou *table
  stakes* (a própria Receita já faz push). Precisa existir para não parecer atrasado.
- **Copy anti-achômetro, seca e humana.** Headline na dor ("pare de cobrar barato",
  "chega de conta de padaria"). A comunidade dev **rejeita texto com cheiro de IA** —
  copy genérica queima confiança.
- **Modificadores de preço** (urgência, cliente difícil, revisões, risco de calote):
  respondem à objeção nº1 "cada caso é um caso / depende do cliente".
- **Número tributário posicionado como PISO/estimativa**, nunca como "a verdade" —
  responde à objeção "você cobra pelo que vale pro cliente, não pelo que custa".

---

## 4. Alertas (onde é fácil errar e caro)

1. 🔴 **Nunca copiar "25–30%" no BR.** Valide DAS/faixas do Simples/IRPF/INSS nas
   fontes oficiais da Receita antes de publicar. Erro fiscal mata a credibilidade
   que é o diferencial.
2. 🔴 **Defaults não podem desvalorizar.** Um default de valor-hora indigno (o
   equivalente ao "8 USD/h" que revoltou a comunidade gringa) sabota a tese "você
   cobra pouco". O chute inicial tem que ser digno.
3. 🟡 **Não se passar por app do governo.** Metade das ★1 do setor MEI é confusão
   com o app oficial + cobrança escondida. Preço transparente, sem cadastro-armadilha.
4. 🟡 **Emitir DAS/DARF de verdade é caro e é a maior fonte de ★1 do setor.** Começar
   por "reservar + quando + lembrete" e **linkar o app oficial** pra emissão reduz risco.

---

## 5. Público, vocabulário e ASO

**Profissões mais vocais** (ordem de volume no Reddit BR): dev/dados · designer ·
fotógrafo/videomaker · social media/tráfego · redator · beleza. **"Freela pra
gringo"** (recebe em dólar via Fiverr/Deel/Wise) é onde a dor do imposto pega mais forte.

**Vocabulário real (para ASO e copy):**
- Núcleo: **"quanto cobrar"** · **freela** (mais usado que "freelancer" no corpo) ·
  **precificar/precificação** · **cobrei barato / cobrar de menos** · **valor da hora / R$X/h** ·
  tabela de preço · orçamento/proposta · escopo.
- Fiscal: **carnê-leão** ("carne leão") · **MEI/DAS/DARF** · **"o Leão"** ·
  imposto pela nota · malha fina · reservar/recolher imposto · Simples Nacional.
- Gíria/emoção (copy de anúncio): **"conta de padaria"** · "me arrependi" · "tomei um
  preju" · "piada de mau gosto" · "merreca" · "subestimar meu trabalho".

**Recomendação ASO:** o diferencial fiscal (imposto a reservar / lucro real) tem
**concorrência baixa em app** e demanda real — é o cluster a cravar. Título Play no
modelo `Marca: Calculadora Freela · Quanto Cobrar`; descrição curta *"Calcule quanto
cobrar por hora: preço, imposto a reservar e lucro real."*

---

## 6. Naming — o alerta e a direção

**"Quanto Cobro?" — problemas:** (a) a query real é "quanto cob**rar**" (infinitivo),
não "cob**ro**" (1ª pessoa) → perde o match da própria keyword que o inspirou;
(b) "cobro" ecoa **cobrança** (contas a receber), não precificação; (c) a "?" é ruído
para Play/handle/domínio; (d) frase descritiva é **marca fraca** (difícil registrar no
INPI, compete com o SEO de dezenas de "Quanto Cobrar?").

**Direção recomendada:** marca própria registrável + keywords no subtítulo do título
da Play (modelo FreelaCalc). Guardar **"Quanto Cobro?" como tagline de marketing** —
ali a 1ª pessoa e o "?" funcionam sem custar ASO.

**Candidatos** (todos com checagem de INPI/domínio/homônimo ainda pendente):
- Marca forte: **Cobro Justo** · **Cobra Certo** ("cobrar certo")
- Meio-termo descritivo: **Precifica Freela**
- Descritivo puro (marca fraca, achabilidade máxima): **Quanto Cobrar** (sem "?") · **Calculadora Freela**

---

## 7. Concorrentes de referência (quadro)

| Concorrente | O que é | Por que importa |
|---|---|---|
| **FreelaCalc** (Play) | Calculadora freela, 4 modelos, offline, 100+ instal., com ads | O mais próximo do blueprint; mas "Simples Nacional" 0×, ad-supported |
| **Calculadora Freelance** (aleckrh, Play) | "Ferramenta simples", 1 mil+ instal. | O mais instalado do nicho direto — e é raso |
| **calculadorabrasil.com.br** | Gross-up com MEI/Simples/IRPF/ISS/INSS | O benchmark fiscal a bater — mas é **web** (sem app/offline) |
| **Freelaz** (web) | Quer ser "o Glassdoor dos freelas BR" | Valida demanda; benchmark de mercado é ideia forte |
| **Apreço / Peqart** (iOS, produto) | Precificação de produto físico | Adjacentes; espelham as dores de paywall caro e cadastro-armadilha |
| **Keeper** (US) | Reserva de imposto por trimestre | Único que chega perto de "reservar por pagamento" — mas é contabilidade cara |

---

## 8. Registro de honestidade (o que NÃO foi verificado)

- **Texto e nota de reviews da Google Play** não são extraíveis (renderizados via JS).
  As notas/instalações da Play vêm de snippets — tratar como aproximação.
- **Tese 2 (imposto) não tem verbatim em review de app** — é validada por comunidade
  (Reddit/Receita), com volume espontâneo menor que a dor de precificação.
- **INPI/trademark, domínios `.com.br` e handles** — não verificados; checagem manual
  antes de fechar nome.
- **Cobertura em espanhol / mercado LatAm** ficou fraca na frente internacional.
- Reviews iOS verbatim (via RSS oficial da Apple) **são** confiáveis.

---

## 9. Próximos passos sugeridos (nada executado sem teu ok)

1. **Decidir a direção de nome** (marca própria vs. descritivo) — destrava ASO, ícone e domínio.
2. **Atualizar o UX Blueprint** com os ajustes: reserva por pagamento como núcleo,
   alíquota efetiva visível, copy anti-achômetro, modificadores de preço, número como piso.
3. **Validar as tabelas fiscais na Receita** (DAS/Simples/IRPF/INSS) — pré-requisito de build.
4. Só então seguir para o **Agente 3 (Design System)** → build Flutter.

---

*Síntese produzida a partir das 5 frentes em [`raw/`](raw/). Todas as afirmações
rastreiam para lá, com URLs. Documento de pesquisa — não altera o blueprint por si só.*
