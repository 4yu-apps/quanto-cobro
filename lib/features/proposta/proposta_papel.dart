import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/common/datas.dart';
import '../../core/common/money.dart';
import '../../core/model/marca.dart';
import '../../core/model/proposta.dart';

/// O documento como o cliente vai vê-lo, na tela (07 §A.3, passo 4).
///
/// Espelha o layout de `core/proposta/proposta_pdf.dart` de propósito: a
/// promessa da pré-visualização é "isto é exatamente o que ele recebe". Se um
/// dos dois mudar, o outro muda junto — é a única duplicação que este app
/// aceita, e existe porque renderizar PDF na tela exigiria arrastar um plugin
/// nativo de impressão só pra espiar.
///
/// Sempre CLARO, mesmo no tema escuro do app: o cliente recebe papel branco,
/// e mostrar um preview escuro seria mentir sobre o resultado.
class PropostaPapel extends StatelessWidget {
  const PropostaPapel({
    super.key,
    required this.proposta,
    required this.marca,
    required this.emitidaEm,
  });

  final Proposta proposta;
  final Marca marca;
  final DateTime emitidaEm;

  static const Color _tinta = Color(0xFF15201C);
  static const Color _tintaSuave = Color(0xFF6A736F);
  static const Color _linha = Color(0xFFDDE3E0);

  static const Color _fundoValor = Color(0xFFF3F7F5);

  @override
  Widget build(BuildContext context) {
    final String? logoPath = marca.logoPath;
    final bool temLogo = logoPath != null && File(logoPath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (temLogo) ...<Widget>[
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 40,
                          maxWidth: 150,
                        ),
                        child: Image.file(
                          File(logoPath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      if (marca.nome.trim().isNotEmpty)
                        const SizedBox(height: 8),
                    ],
                    if (marca.nome.trim().isNotEmpty)
                      Text(
                        marca.nome.trim(),
                        style: const TextStyle(
                          color: _tinta,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    'PROPOSTA',
                    style: TextStyle(
                      color: Color(marca.cor),
                      fontSize: 8,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (marca.contatoFormatado.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      marca.contatoFormatado.trim(),
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: _tintaSuave, fontSize: 9.5),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: _linha),
          const SizedBox(height: 22),

          if (proposta.cliente.trim().isNotEmpty) ...<Widget>[
            _rotulo('PARA'),
            const SizedBox(height: 4),
            Text(
              proposta.cliente.trim(),
              style: const TextStyle(
                color: _tinta,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
          ],

          if (proposta.servico.trim().isNotEmpty) ...<Widget>[
            _rotulo('SERVIÇO'),
            const SizedBox(height: 4),
            Text(
              proposta.servico.trim(),
              style: const TextStyle(
                color: _tinta,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (proposta.descricao.trim().isNotEmpty) ...<Widget>[
            Text(
              proposta.descricao.trim(),
              style: const TextStyle(
                color: _tinta,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 12),
          _blocoValor(),
          const SizedBox(height: 30),

          _rotulo('CONDIÇÕES'),
          const SizedBox(height: 12),
          if (proposta.prazo.trim().isNotEmpty)
            _condicao('Prazo de entrega', proposta.prazo.trim()),
          _condicao('Validade da proposta', _validade),
          if (proposta.formaPagamento.trim().isNotEmpty)
            _condicao('Pagamento', proposta.formaPagamento.trim()),

          if (proposta.observacoes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            _rotulo('OBSERVAÇÕES'),
            const SizedBox(height: 8),
            Text(
              proposta.observacoes.trim(),
              style: const TextStyle(
                color: _tinta,
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 0.7, color: _linha),
          const SizedBox(height: 8),
          Text(
            'Proposta gerada em ${dataNumerica(emitidaEm)} · válida por $_validade.',
            style: const TextStyle(color: _tintaSuave, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  String get _validade =>
      proposta.validadeDias == 1 ? '1 dia' : '${proposta.validadeDias} dias';

  Widget _rotulo(String texto) => Text(
    texto,
    style: const TextStyle(
      color: _tintaSuave,
      fontSize: 7.5,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _blocoValor() => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: ColoredBox(
      color: Color(marca.cor),
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: ColoredBox(
          color: _fundoValor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _rotulo('VALOR'),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _valorFormatado(proposta.valor),
                    maxLines: 1,
                    style: const TextStyle(
                      color: _tinta,
                      fontSize: 30,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (proposta.temDetalheHoras) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    '${proposta.horas} ${proposta.horas == 1 ? 'hora' : 'horas'}'
                    ' × ${_valorFormatado(proposta.valorHora!)}',
                    style: const TextStyle(color: _tintaSuave, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _condicao(String rotulo, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 120,
          child: Text(
            rotulo,
            style: const TextStyle(color: _tintaSuave, fontSize: 10),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: _tinta,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );

  /// Mesma regra do PDF: reais redondos sem centavo, valor quebrado com — o
  /// preço do documento não pode ser arredondado.
  String _valorFormatado(double valor) {
    final bool redondo = (valor - valor.roundToDouble()).abs() < 0.005;
    return redondo ? moneyBRL(valor.roundToDouble()) : moneyBRLCents(valor);
  }
}
