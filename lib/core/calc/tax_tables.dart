/// Ano-base das tabelas fiscais embutidas (DAS/Simples/IRPF/INSS). As alíquotas
/// em `Regime` são desse ano. VALIDAR na Receita antes de publicar (regra R5) e
/// atualizar ~1x/ano. Quando o ano corrente passa deste, o app mostra uma faixa
/// calma "valores base de [ano]" (nunca alarme).
const int kTabelasAno = 2025;

/// Verdadeiro quando as tabelas embutidas estão defasadas em relação ao ano atual.
bool tabelasDefasadas(DateTime agora) => agora.year > kTabelasAno;
