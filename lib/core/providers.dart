import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing/entitlement.dart';
import 'data/backup_service.dart';
import 'data/marca_repository.dart';
import 'data/profile_repository.dart';
import 'data/projeto_repository.dart';
import 'data/reserva_history_repository.dart';
import 'fx/fx_repository.dart';
import 'fx/fx_service.dart';
import 'model/marca.dart';
import 'model/perfil.dart';
import 'model/projeto.dart';
import 'model/reserva_entry.dart';
import 'settings/settings_repository.dart';

/// Injetado em main() via override (prefs já carregado no boot).
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError('override em main()'),
    );

final Provider<ProfileRepository> profileRepositoryProvider =
    Provider<ProfileRepository>(
      (Ref ref) => PrefsProfileRepository(ref.watch(sharedPreferencesProvider)),
    );

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
    );

/// Estado do perfil ATIVO — três ramos explícitos (Blueprint §5.9):
/// vazio (nunca calculou) · pronto · erro (dado salvo corrompido).
sealed class ProfileState {
  const ProfileState();
}

class ProfileEmpty extends ProfileState {
  const ProfileEmpty();
}

class ProfileReady extends ProfileState {
  const ProfileReady(this.perfil);
  final Perfil perfil;
}

class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}

/// Todos os perfis (cada "caso" do usuário: freela X, cliente fixo, outro
/// emprego) + qual está ativo. É a fonte da verdade; o profileProvider deriva.
class ProfilesNotifier extends Notifier<ProfilesData> {
  @override
  ProfilesData build() {
    try {
      return ref.read(profileRepositoryProvider).loadSync();
    } catch (_) {
      // Dado corrompido: trata como vazio com flag de erro via provider derivado.
      _corrupt = true;
      return const ProfilesData(perfis: <Perfil>[], activeId: null);
    }
  }

  bool _corrupt = false;
  bool get corrupt => _corrupt;

  Future<void> _persist(ProfilesData data) async {
    await ref.read(profileRepositoryProvider).saveAll(data);
    _corrupt = false; // dado regravado com sucesso: sai do estado de erro
    state = data;
  }

  /// Salva o perfil (novo id = cria; id existente = atualiza) e o torna ativo.
  Future<void> saveAndActivate(Perfil perfil) async {
    final List<Perfil> list = List<Perfil>.of(state.perfis);
    final int i = list.indexWhere((Perfil p) => p.id == perfil.id);
    if (i >= 0) {
      list[i] = perfil;
    } else {
      list.add(perfil);
    }
    await _persist(ProfilesData(perfis: list, activeId: perfil.id));
  }

  Future<void> select(String id) async {
    await _persist(ProfilesData(perfis: state.perfis, activeId: id));
  }

  Future<void> remove(String id) async {
    final List<Perfil> list = state.perfis
        .where((Perfil p) => p.id != id)
        .toList();
    final String? active = state.activeId == id
        ? (list.isEmpty ? null : list.first.id)
        : state.activeId;
    await _persist(ProfilesData(perfis: list, activeId: active));
  }

  Future<void> rename(String id, String nome) async {
    final List<Perfil> list = <Perfil>[
      for (final Perfil p in state.perfis)
        p.id == id ? p.copyWith(nome: nome) : p,
    ];
    await _persist(ProfilesData(perfis: list, activeId: state.activeId));
  }

  Future<void> clearAll() async {
    await ref.read(profileRepositoryProvider).clear();
    _corrupt = false;
    state = const ProfilesData(perfis: <Perfil>[], activeId: null);
  }
}

final NotifierProvider<ProfilesNotifier, ProfilesData> profilesProvider =
    NotifierProvider<ProfilesNotifier, ProfilesData>(ProfilesNotifier.new);

/// Estado do perfil ativo, derivado (mantém a API que as telas consomem).
final Provider<ProfileState> profileProvider = Provider<ProfileState>((
  Ref ref,
) {
  final ProfilesData data = ref.watch(profilesProvider);
  if (ref.read(profilesProvider.notifier).corrupt) {
    return const ProfileError(
      'Não consegui carregar seu cálculo. Vamos refazer?',
    );
  }
  final Perfil? active = data.active;
  return active == null ? const ProfileEmpty() : ProfileReady(active);
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(settingsRepositoryProvider).themeMode();

  Future<void> set(ThemeMode mode) async {
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
    state = mode;
  }
}

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// ---- Backup (export/import por texto, sem nuvem) ----
final Provider<BackupService> backupServiceProvider = Provider<BackupService>(
  (Ref ref) => BackupService(
    ref.watch(profileRepositoryProvider),
    ref.watch(reservaHistoryRepositoryProvider),
    ref.watch(projetoRepositoryProvider),
    ref.watch(marcaRepositoryProvider),
  ),
);

// ---- Entitlement Pro ----
final Provider<EntitlementRepository> entitlementRepositoryProvider =
    Provider<EntitlementRepository>(
      (Ref ref) => EntitlementRepository(ref.watch(sharedPreferencesProvider)),
    );

class ProNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(entitlementRepositoryProvider).isPro();

  /// Concede o Pro. Hoje grava o entitlement local; quando a compra real pela
  /// loja for ligada com os IDs da Play, ela chama isto no sucesso.
  Future<void> grant() async {
    await ref.read(entitlementRepositoryProvider).setPro(true);
    state = true;
  }

  Future<void> revoke() async {
    await ref.read(entitlementRepositoryProvider).setPro(false);
    state = false;
  }
}

final NotifierProvider<ProNotifier, bool> proProvider =
    NotifierProvider<ProNotifier, bool>(ProNotifier.new);

// ---- Telemetria (opt-in, LGPD) ----
class TelemetryNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).telemetryEnabled();

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setTelemetry(value);
    state = value;
    // Quando o Firebase for ligado, aplicar aqui o opt-in de Analytics/Crashlytics.
  }
}

final NotifierProvider<TelemetryNotifier, bool> telemetryProvider =
    NotifierProvider<TelemetryNotifier, bool>(TelemetryNotifier.new);

// ---- Reduzir transparência (habilita o fallback opaco da navbar) ----
class ReduceTransparencyNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).reduceTransparency();

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setReduceTransparency(value);
    state = value;
  }
}

final NotifierProvider<ReduceTransparencyNotifier, bool>
reduceTransparencyProvider = NotifierProvider<ReduceTransparencyNotifier, bool>(
  ReduceTransparencyNotifier.new,
);

// ---- Escala de texto (tamanho relativo da fonte) ----
class TextScaleNotifier extends Notifier<double> {
  @override
  double build() => ref.read(settingsRepositoryProvider).textScale();

  Future<void> set(double v) async {
    await ref.read(settingsRepositoryProvider).setTextScale(v);
    state = v;
  }
}

final NotifierProvider<TextScaleNotifier, double> textScaleProvider =
    NotifierProvider<TextScaleNotifier, double>(TextScaleNotifier.new);

// ---- Lembrete mensal (nudge in-app pra trabalhos recorrentes) ----
class ReminderMensalNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).reminderMensal();

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setReminderMensal(value);
    state = value;
  }
}

final NotifierProvider<ReminderMensalNotifier, bool> reminderMensalProvider =
    NotifierProvider<ReminderMensalNotifier, bool>(ReminderMensalNotifier.new);

// ---- Histórico de reservas (gancho de hábito, IA §2.12) ----
final Provider<ReservaHistoryRepository> reservaHistoryRepositoryProvider =
    Provider<ReservaHistoryRepository>(
      (Ref ref) =>
          ReservaHistoryRepository(ref.watch(sharedPreferencesProvider)),
    );

class ReservaHistoryNotifier extends Notifier<List<ReservaEntry>> {
  @override
  List<ReservaEntry> build() =>
      ref.read(reservaHistoryRepositoryProvider).loadAll();

  Future<void> add(ReservaEntry entry) async {
    await ref.read(reservaHistoryRepositoryProvider).add(entry);
    state = ref.read(reservaHistoryRepositoryProvider).loadAll();
  }

  Future<void> clear() async {
    await ref.read(reservaHistoryRepositoryProvider).clear();
    state = <ReservaEntry>[];
  }

  /// Remove uma entrada (Desfazer / swipe). Reescreve a lista persistida.
  Future<void> remove(ReservaEntry entry) async {
    final List<ReservaEntry> all = List<ReservaEntry>.of(state)
      ..removeWhere(
        (ReservaEntry e) => e.at == entry.at && e.valor == entry.valor,
      );
    await ref.read(reservaHistoryRepositoryProvider).replaceAll(all);
    state = all;
  }

  /// Reinsere uma entrada (Desfazer do swipe).
  Future<void> restore(ReservaEntry entry) async {
    final List<ReservaEntry> all = List<ReservaEntry>.of(state)
      ..insert(0, entry)
      ..sort((ReservaEntry a, ReservaEntry b) => b.at.compareTo(a.at));
    await ref.read(reservaHistoryRepositoryProvider).replaceAll(all);
    state = all;
  }
}

final NotifierProvider<ReservaHistoryNotifier, List<ReservaEntry>>
reservaHistoryProvider =
    NotifierProvider<ReservaHistoryNotifier, List<ReservaEntry>>(
      ReservaHistoryNotifier.new,
    );

/// "Já paguei o imposto deste mês" — quitação mensal (fecha o loop da reserva).
/// Estado = o mês corrente está quitado?
class LeaoPagoNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).leaoPago(DateTime.now());

  Future<void> set(bool pago) async {
    await ref
        .read(settingsRepositoryProvider)
        .setLeaoPago(DateTime.now(), pago);
    state = pago;
  }
}

final NotifierProvider<LeaoPagoNotifier, bool> leaoPagoProvider =
    NotifierProvider<LeaoPagoNotifier, bool>(LeaoPagoNotifier.new);

// ---- Projetos (07 §B — a gestão pendurada no loop de reserva) ----
final Provider<ProjetoRepository> projetoRepositoryProvider =
    Provider<ProjetoRepository>(
      (Ref ref) => ProjetoRepository(ref.watch(sharedPreferencesProvider)),
    );

class ProjetosNotifier extends Notifier<List<Projeto>> {
  @override
  List<Projeto> build() => ordenarPorProximoRecebimento(
    ref.read(projetoRepositoryProvider).loadAll(),
  );

  Future<void> _persist(List<Projeto> all) async {
    final List<Projeto> ordenado = ordenarPorProximoRecebimento(all);
    await ref.read(projetoRepositoryProvider).replaceAll(ordenado);
    state = ordenado;
  }

  /// Cria (id novo) ou atualiza (id existente).
  Future<void> save(Projeto projeto) async {
    final List<Projeto> all = List<Projeto>.of(state);
    final int i = all.indexWhere((Projeto p) => p.id == projeto.id);
    if (i >= 0) {
      all[i] = projeto;
    } else {
      all.add(projeto);
    }
    await _persist(all);
  }

  Future<void> remove(String id) =>
      _persist(state.where((Projeto p) => p.id != id).toList());

  Future<void> setStatus(String id, ProjetoStatus status) async {
    final Projeto? p = byId(id);
    if (p == null) return;
    await save(p.copyWith(status: status));
  }

  /// Fecha o ciclo: registrado o recebimento, a data anda pro próximo (07 §B.4).
  ///
  /// O avulso NÃO é concluído automaticamente — o default de pagamento do app
  /// é "50% de sinal, 50% na entrega", então o primeiro "Recebi" de um avulso
  /// costuma ser metade do trabalho, não o fim dele. Concluir sozinho aqui
  /// apagaria o projeto da lista bem no meio do serviço.
  Future<void> registrarRecebimento(
    String id, {
    required DateTime pagoEm,
  }) async {
    final Projeto? p = byId(id);
    if (p == null) return;
    final DateTime? proximo = avancarCiclo(p, pagoEm: pagoEm);
    await save(
      p.copyWith(
        proximoRecebimento: proximo,
        limparProximoRecebimento: proximo == null,
        // Orçamento que recebeu virou trabalho de verdade: o cliente aceitou.
        status: p.status == ProjetoStatus.orcamento
            ? ProjetoStatus.ativo
            : null,
      ),
    );
  }

  Projeto? byId(String? id) {
    if (id == null) return null;
    for (final Projeto p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> clearAll() async {
    await ref.read(projetoRepositoryProvider).clear();
    state = <Projeto>[];
  }
}

final NotifierProvider<ProjetosNotifier, List<Projeto>> projetosProvider =
    NotifierProvider<ProjetosNotifier, List<Projeto>>(ProjetosNotifier.new);

// ---- Marca do freelancer (o topo da proposta — 07 §A.2) ----
final Provider<MarcaRepository> marcaRepositoryProvider =
    Provider<MarcaRepository>(
      (Ref ref) => MarcaRepository(ref.watch(sharedPreferencesProvider)),
    );

class MarcaNotifier extends Notifier<Marca> {
  @override
  Marca build() => ref.read(marcaRepositoryProvider).load();

  Future<void> save(Marca marca) async {
    await ref.read(marcaRepositoryProvider).save(marca);
    state = marca;
  }

  /// Copia a imagem escolhida pra pasta do app e já salva na marca.
  Future<void> setLogo(String origem) async {
    final String path = await ref
        .read(marcaRepositoryProvider)
        .importarLogo(origem);
    await save(state.copyWith(logoPath: path));
  }

  Future<void> removerLogo() async {
    await save(state.copyWith(limparLogo: true));
  }
}

final NotifierProvider<MarcaNotifier, Marca> marcaProvider =
    NotifierProvider<MarcaNotifier, Marca>(MarcaNotifier.new);

// ---- Câmbio (Fase 3 — cliente estrangeiro, ex.: Marina cobrando em USD) ----
final Provider<FxRepository> fxRepositoryProvider = Provider<FxRepository>(
  (Ref ref) => FxRepository(ref.watch(sharedPreferencesProvider)),
);

final Provider<FxService> fxServiceProvider = Provider<FxService>(
  (Ref ref) => FxService(ref.watch(fxRepositoryProvider)),
);
