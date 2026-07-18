/* ============================================================
   QUANTO EU COBRO?  ·  model.jsx
   Modelo de dados + motor de cálculo (coerente em todas as telas).
   Números ilustrativos de planejamento (validar tabelas na Receita).
   ============================================================ */

/* regimes — "como você trabalha?" → alíquota nos bastidores (§6.9 / §7.2) */
const REGIMES = {
  mei:     { id: "mei",     label: "Sou MEI",                     sub: "DAS fixo mensal, imposto baixo", reserveRate: 0.16, tag: "MEI" },
  cpf:     { id: "cpf",     label: "Autônomo (CPF)",              sub: "Carnê-leão + INSS",              reserveRate: 0.275, tag: "Autônomo" },
  simples: { id: "simples", label: "Tenho empresa no Simples",    sub: "Alíquota por faixa",             reserveRate: 0.12, tag: "Simples" },
  intl:    { id: "intl",    label: "Não sei / cliente no exterior", sub: "Reserva padrão 25–30%",        reserveRate: 0.27, tag: "Internacional" },
};

/* 11 chips de lembrança (§5.5 / §12) */
const COST_CHIPS = [
  { id: "contador",   label: "Contador",        icon: "calculate",          sugg: 200 },
  { id: "coworking",  label: "Coworking",       icon: "chair",              sugg: 280 },
  { id: "cursos",     label: "Cursos",          icon: "school",             sugg: 120 },
  { id: "energia",    label: "Energia",         icon: "bolt",               sugg: 90  },
  { id: "internet",   label: "Internet/telefone", icon: "wifi",             sugg: 100 },
  { id: "equip",      label: "Equipamento",     icon: "devices",            sugg: 150 },
  { id: "prolabore",  label: "Pró-labore",      icon: "account_balance",    sugg: 0   },
  { id: "saude",      label: "Plano de saúde",  icon: "health_and_safety",  sugg: 350 },
  { id: "software",   label: "Software",        icon: "apps",               sugg: 120 },
  { id: "marketing",  label: "Marketing",       icon: "campaign",           sugg: 80  },
  { id: "transporte", label: "Transporte",      icon: "directions_car",     sugg: 120 },
];

/* perfil canônico (resultado coerente: R$ 92/hora) */
function defaultProfile() {
  return {
    nome: "Padrão",
    renda: 5000,                 // o que você quer que sobre, no bolso
    horas: 82,                   // horas faturáveis/mês (realista — não são 160h)
    provisao: 458,               // férias + 13º
    provisaoOn: true,
    regime: "mei",
    custos: [
      { id: "software",  label: "Software/ferramentas", valor: 120 },
      { id: "internet",  label: "Internet/telefone",    valor: 100 },
      { id: "equip",     label: "Equipamento (rateio)", valor: 150 },
      { id: "contador",  label: "Contador",             valor: 200 },
      { id: "coworking", label: "Coworking",            valor: 280 },
    ],
  };
}

function custosTotal(p) { return p.custos.reduce((s, c) => s + (c.valor || 0), 0); }

/* núcleo: valor-hora justo (§6.13) */
function computeValorHora(p) {
  const rate = REGIMES[p.regime].reserveRate;
  const provisao = p.provisaoOn ? p.provisao : 0;
  const custos = custosTotal(p);
  const base = p.renda + custos + provisao;        // o que precisa sobrar antes do imposto
  const faturamento = base / (1 - rate);            // grossa-up p/ cobrir o imposto
  const imposto = faturamento - base;
  const valorHora = faturamento / Math.max(1, p.horas);
  return {
    rate, provisao, custos, base, faturamento, imposto,
    valorHora: Math.round(valorHora),
    valorDia: Math.round(valorHora * 8),
    reservaPct: Math.round(rate * 100),
    lucro: p.renda,
  };
}

/* a Divisão a partir do perfil (Lucro = é seu + provisão · Reserva = imposto · Custos) */
function divisaoFromProfile(p, comp) {
  return {
    parts: { lucro: p.renda + comp.provisao, reserva: comp.imposto, custo: comp.custos },
    base: comp.faturamento,
  };
}

/* tool: reserva por pagamento (§5.5) */
function computeReserva(amount, regimeId) {
  const rate = REGIMES[regimeId].reserveRate;
  const reserva = Math.round(amount * rate);
  return { rate, reserva, sobra: amount - reserva, pct: Math.round(rate * 100) };
}

/* tool: simulador de projeto (§5.6) */
function computeSimulador(valor, horas, custos, regimeId, alvoVH) {
  const rate = REGIMES[regimeId].reserveRate;
  const reserva = Math.round(valor * rate);
  const lucro = valor - reserva - custos;
  const effVH = horas > 0 ? Math.round(lucro / horas) : 0;
  const abaixo = horas > 0 && effVH < alvoVH;
  // valor sugerido p/ atingir o alvo: lucro_alvo = alvoVH*horas → valor = (lucro_alvo + custos)/(1-rate)
  const sugestao = Math.round(((alvoVH * horas) + custos) / (1 - rate) / 10) * 10;
  return {
    rate, reserva, lucro, effVH, abaixo, sugestao,
    parts: { lucro: Math.max(0, lucro), reserva, custo: custos }, base: valor,
  };
}

Object.assign(window, {
  REGIMES, COST_CHIPS, defaultProfile, custosTotal,
  computeValorHora, divisaoFromProfile, computeReserva, computeSimulador,
});
