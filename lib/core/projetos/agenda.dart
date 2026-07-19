import '../model/projeto.dart';
import '../model/reserva_entry.dart';

/// Um recebimento que a pessoa ESPERA — a previsão de caixa (07 §B.5 v2).
class RecebimentoPrevisto {
  const RecebimentoPrevisto({
    required this.projeto,
    required this.data,
    required this.atrasado,
  });

  final Projeto projeto;
  final DateTime data;

  /// Data já passou e nada foi registrado. Mostrar isso é metade do valor da
  /// tela: o susto que a Camila quer evitar é justamente o que ela esqueceu.
  final bool atrasado;

  double get valor => projeto.valor;
}

/// Os recebimentos esperados de [de] até [dias] à frente, mais os atrasados.
///
/// Só projetos ATIVOS entram: orçamento é proposta que talvez nem seja aceita,
/// e prometer caixa que pode não vir é pior que não prometer nada (07 §B.3).
/// Um projeto aparece uma vez só — a próxima data dele —, mesmo mensal: a
/// pergunta que a tela responde é "quem me paga quando", não "quantas vezes".
List<RecebimentoPrevisto> proximosRecebimentos(
  List<Projeto> projetos, {
  required DateTime de,
  int dias = 30,
}) {
  final DateTime hoje = DateTime(de.year, de.month, de.day);
  final DateTime limite = hoje.add(Duration(days: dias));
  final List<RecebimentoPrevisto> out = <RecebimentoPrevisto>[];

  for (final Projeto p in projetos) {
    final DateTime? data = p.proximoRecebimento;
    if (data == null || !p.status.esperaRecebimento) continue;
    final DateTime dia = DateTime(data.year, data.month, data.day);
    if (dia.isAfter(limite)) continue;
    out.add(
      RecebimentoPrevisto(projeto: p, data: dia, atrasado: dia.isBefore(hoje)),
    );
  }

  out.sort(
    (RecebimentoPrevisto a, RecebimentoPrevisto b) => a.data.compareTo(b.data),
  );
  return out;
}

/// Quanto cada projeto já pagou, somando o histórico que JÁ existe (07 §C).
/// Nenhum dado novo: "já recebeu R$ 4.200" sai daqui.
Map<String, double> recebidoPorProjeto(List<ReservaEntry> historico) {
  final Map<String, double> out = <String, double>{};
  for (final ReservaEntry e in historico) {
    final String? id = e.projetoId;
    // Entrada de DAS é imposto separado, não faturamento — somar ela como
    // "recebido do cliente" inflaria o total do projeto.
    if (id == null || e.isDas) continue;
    out[id] = (out[id] ?? 0) + e.valor;
  }
  return out;
}

/// O projeto já teve algum recebimento registrado no mês de [mes]?
/// É o que decide o selo "Leão em dia" e se o nudge mensal cutuca.
bool recebeuNoMes(
  List<ReservaEntry> historico,
  String projetoId,
  DateTime mes,
) {
  return historico.any(
    (ReservaEntry e) =>
        e.projetoId == projetoId &&
        !e.isDas &&
        e.at.year == mes.year &&
        e.at.month == mes.month,
  );
}

/// O selo discreto do card (07 §B.3). Neste app registrar o recebimento É
/// separar a reserva — os dois acontecem no mesmo toque —, então o selo lê
/// exatamente isso, sem inventar um estado que o usuário não controla.
enum SeloReserva {
  emDia, // recebeu e registrou: o do Leão já foi separado
  faltaSeparar, // vencido/vencendo e nada registrado
  nenhum, // nada a dizer ainda — silêncio é melhor que selo cinza
}

SeloReserva seloReserva(
  Projeto projeto,
  List<ReservaEntry> historico,
  DateTime mes,
) {
  if (recebeuNoMes(historico, projeto.id, mes)) return SeloReserva.emDia;
  if (!projeto.status.esperaRecebimento) return SeloReserva.nenhum;
  final DateTime? data = projeto.proximoRecebimento;
  if (data == null) return SeloReserva.nenhum;
  final DateTime fimDoMes = DateTime(mes.year, mes.month + 1, 0);
  return data.isAfter(fimDoMes) ? SeloReserva.nenhum : SeloReserva.faltaSeparar;
}

/// Projetos que merecem cutucada este mês (07 §B.4 — o nudge por-projeto).
///
/// O avulso nunca entra: perguntar todo mês "o freela de março já te pagou?"
/// é ruído. E o TRIMESTRAL só cutuca no ciclo dele — é por isso que a regra
/// olha a data do próximo recebimento, e não só "recebeu algo este mês": sem
/// isso, um projeto a cada 3 meses viraria um alarme mensal falso, e o
/// usuário aprenderia a ignorar o aviso justo quando ele fica verdadeiro.
///
/// Sem data marcada, só o mensal cutuca — é o único caso em que "todo mês"
/// é palpite seguro.
List<Projeto> projetosParaCutucar(
  List<Projeto> projetos,
  List<ReservaEntry> historico,
  DateTime mes,
) {
  final DateTime fimDoMes = DateTime(mes.year, mes.month + 1, 0);
  return projetos.where((Projeto p) {
    if (!p.recorrente || !p.status.esperaRecebimento) return false;
    if (recebeuNoMes(historico, p.id, mes)) return false;
    final DateTime? data = p.proximoRecebimento;
    if (data == null) return p.recorrencia == Recorrencia.mensal;
    return !data.isAfter(fimDoMes); // vence este mês ou já venceu
  }).toList();
}
