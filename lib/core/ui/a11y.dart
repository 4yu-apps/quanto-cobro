import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A "camada sonora" do app (auditoria Amara): anúncios de leitor de tela
/// centralizados. Todo momento que VIBRA ou ANIMA também FALA — o mapa de
/// haptics e o de announces são o mesmo mapa.
void announce(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}
