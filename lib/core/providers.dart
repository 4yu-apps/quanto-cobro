import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing/billing_service.dart';
import 'billing/entitlement.dart';
import 'data/area_repository.dart';
import 'data/backup_service.dart';
import 'data/entrada_repository.dart';
import 'data/marca_repository.dart';
import 'data/trabalho_repository.dart';
import 'fx/fx_repository.dart';
import 'fx/fx_service.dart';
import 'lembrete/lembrete.dart';
import 'model/area.dart';
import 'model/entrada.dart';
import 'model/marca.dart';
import 'model/regime.dart';
import 'model/trabalho.dart';
import 'settings/settings_repository.dart';
import 'telemetry/telemetry.dart';

/// Injetado em main() via override (prefs já carregado no boot).
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError('override em main()'),
    );

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (Ref ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
    );

// ---------------------------------------------------------------------------
// Regime — da PESSOA, não da área (ver settings_repository.dart)
// ---------------------------------------------------------------------------

class RegimeNotifier extends Notifier<RegimeId> {
  @override
  RegimeId build() => ref.read(settingsRepositoryProvider).regime();

  Future<void> set(RegimeId value) async {
    await ref.read(settingsRepositoryProvider).setRegime(value);
    state = value;
  }
}

final NotifierProvider<RegimeNotifier, RegimeId> regimeProvider =
    NotifierProvider<RegimeNotifier, RegimeId>(RegimeNotifier.new);

// ---------------------------------------------------------------------------
// Lembrete de imposto (F7) — notificação mensal, opt-in
// ---------------------------------------------------------------------------

/// O serviço de lembrete. Injetável: os testes trocam por um fake (o plugin
/// nativo não roda em teste de unidade).
final Provider<Lembretes> lembretesProvider = Provider<Lembretes>(
  (Ref ref) => LembreteService(),
);

class LembreteNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).lembreteEnabled();

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setLembrete(value);
    state = value;
  }
}

final NotifierProvider<LembreteNotifier, bool> lembreteProvider =
    NotifierProvider<LembreteNotifier, bool>(LembreteNotifier.new);

// ---------------------------------------------------------------------------
// Áreas de trabalho — onde o cálculo mora
// ---------------------------------------------------------------------------

final Provider<AreaRepository> areaRepositoryProvider =
    Provider<AreaRepository>(
      (Ref ref) => PrefsAreaRepository(ref.watch(sharedPreferencesProvider)),
    );

/// Três ramos explícitos: vazio (nunca calculou) · pronto · erro (dado salvo
/// corrompido). O Painel desenha um estado diferente pra cada.
sealed class AreaState {
  const AreaState();
}

class AreaVazia extends AreaState {
  const AreaVazia();
}

class AreaPronta extends AreaState {
  const AreaPronta(this.area);
  final Area area;
}

class AreaErro extends AreaState {
  const AreaErro(this.message);
  final String message;
}

class AreasNotifier extends Notifier<AreasData> {
  @override
  AreasData build() {
    try {
      return ref.read(areaRepositoryProvider).loadSync();
    } catch (_) {
      _corrompido = true;
      return const AreasData(areas: <Area>[], activeId: null);
    }
  }

  bool _corrompido = false;
  bool get corrompido => _corrompido;

  Future<void> _persist(AreasData data) async {
    await ref.read(areaRepositoryProvider).saveAll(data);
    _corrompido = false; // dado regravado com sucesso: sai do estado de erro
    state = data;
  }

  /// Salva a área (id novo = cria; id existente = atualiza) e a torna ativa.
  Future<void> saveAndActivate(Area area) async {
    final List<Area> list = List<Area>.of(state.areas);
    final int i = list.indexWhere((Area a) => a.id == area.id);
    if (i >= 0) {
      list[i] = area;
    } else {
      list.add(area);
    }
    await _persist(AreasData(areas: list, activeId: area.id));
  }

  Future<void> select(String id) async {
    await _persist(AreasData(areas: state.areas, activeId: id));
  }

  Future<void> remove(String id) async {
    final List<Area> list = state.areas.where((Area a) => a.id != id).toList();
    final String? active = state.activeId == id
        ? (list.isEmpty ? null : list.first.id)
        : state.activeId;
    await _persist(AreasData(areas: list, activeId: active));
  }

  Future<void> rename(String id, String nome) async {
    await _persist(
      AreasData(
        areas: <Area>[
          for (final Area a in state.areas)
            a.id == id ? a.copyWith(nome: nome) : a,
        ],
        activeId: state.activeId,
      ),
    );
  }

  Area? byId(String? id) {
    if (id == null) return null;
    for (final Area a in state.areas) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> clearAll() async {
    await ref.read(areaRepositoryProvider).clear();
    _corrompido = false;
    state = const AreasData(areas: <Area>[], activeId: null);
  }
}

final NotifierProvider<AreasNotifier, AreasData> areasProvider =
    NotifierProvider<AreasNotifier, AreasData>(AreasNotifier.new);

/// Estado da área ATIVA, derivado (é o que as telas consomem).
final Provider<AreaState> areaAtivaProvider = Provider<AreaState>((Ref ref) {
  final AreasData data = ref.watch(areasProvider);
  if (ref.read(areasProvider.notifier).corrompido) {
    return const AreaErro('Não consegui carregar seu cálculo. Vamos refazer?');
  }
  final Area? active = data.active;
  return active == null ? const AreaVazia() : AreaPronta(active);
});

// ---------------------------------------------------------------------------
// Trabalhos
// ---------------------------------------------------------------------------

final Provider<TrabalhoRepository> trabalhoRepositoryProvider =
    Provider<TrabalhoRepository>(
      (Ref ref) => TrabalhoRepository(ref.watch(sharedPreferencesProvider)),
    );

class TrabalhosNotifier extends Notifier<List<Trabalho>> {
  @override
  List<Trabalho> build() => ref.read(trabalhoRepositoryProvider).loadAll();

  Future<void> _persist(List<Trabalho> all) async {
    await ref.read(trabalhoRepositoryProvider).replaceAll(all);
    state = all;
  }

  Future<void> save(Trabalho trabalho) async {
    final List<Trabalho> all = List<Trabalho>.of(state);
    final int i = all.indexWhere((Trabalho t) => t.id == trabalho.id);
    if (i >= 0) {
      all[i] = trabalho;
    } else {
      all.add(trabalho);
    }
    await _persist(all);
  }

  /// Cria um trabalho a partir do nome digitado na primeira entrada — é assim
  /// que ele nasce no fluxo principal, nunca de um formulário vazio.
  Future<Trabalho> criarPorNome(String nome, {required String areaId}) async {
    final Trabalho t = Trabalho(
      id: 'tr_${DateTime.now().microsecondsSinceEpoch}',
      areaId: areaId,
      nome: nome.trim(),
      criadoEm: DateTime.now(),
    );
    await save(t);
    return t;
  }

  Future<void> remove(String id) =>
      _persist(state.where((Trabalho t) => t.id != id).toList());

  Future<void> setEncerrado(String id, bool encerrado) async {
    final Trabalho? t = byId(id);
    if (t == null) return;
    await save(t.copyWith(encerrado: encerrado));
  }

  Trabalho? byId(String? id) {
    if (id == null) return null;
    for (final Trabalho t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Um trabalho já existente com esse nome, nesta área — evita criar
  /// "Augusto" duas vezes quando a pessoa digita de novo na entrada seguinte.
  Trabalho? porNome(String nome, {required String areaId}) {
    final String alvo = nome.trim().toLowerCase();
    for (final Trabalho t in state) {
      if (t.areaId == areaId && t.nome.trim().toLowerCase() == alvo) return t;
    }
    return null;
  }

  Future<void> clearAll() async {
    await ref.read(trabalhoRepositoryProvider).clear();
    state = <Trabalho>[];
  }
}

final NotifierProvider<TrabalhosNotifier, List<Trabalho>> trabalhosProvider =
    NotifierProvider<TrabalhosNotifier, List<Trabalho>>(TrabalhosNotifier.new);

// ---------------------------------------------------------------------------
// Entradas — o objeto do hábito
// ---------------------------------------------------------------------------

final Provider<EntradaRepository> entradaRepositoryProvider =
    Provider<EntradaRepository>(
      (Ref ref) => EntradaRepository(ref.watch(sharedPreferencesProvider)),
    );

class EntradasNotifier extends Notifier<List<Entrada>> {
  @override
  List<Entrada> build() => ref.read(entradaRepositoryProvider).loadAll();

  Future<void> add(Entrada entrada) async {
    await ref.read(entradaRepositoryProvider).add(entrada);
    state = ref.read(entradaRepositoryProvider).loadAll();
  }

  /// Liga uma entrada avulsa a um trabalho, depois do fato (histórico). Localiza
  /// pela marca de tempo + valor (a `at` tem precisão de microssegundo, é única
  /// na prática) e só toca numa entrada que ainda estava avulsa.
  Future<void> setTrabalho(Entrada entrada, String trabalhoId) async {
    final List<Entrada> all = List<Entrada>.of(state);
    final int i = all.indexWhere(
      (Entrada e) =>
          e.at == entrada.at &&
          e.valor == entrada.valor &&
          e.trabalhoId == null,
    );
    if (i < 0) return;
    all[i] = all[i].copyWith(trabalhoId: trabalhoId);
    await ref.read(entradaRepositoryProvider).replaceAll(all);
    state = all;
  }

  /// Remove uma entrada (Desfazer / swipe).
  Future<void> remove(Entrada entrada) async {
    final List<Entrada> all = List<Entrada>.of(state)
      ..removeWhere(
        (Entrada e) => e.at == entrada.at && e.valor == entrada.valor,
      );
    await ref.read(entradaRepositoryProvider).replaceAll(all);
    state = all;
  }

  Future<void> restore(Entrada entrada) async {
    final List<Entrada> all = List<Entrada>.of(state)
      ..insert(0, entrada)
      ..sort((Entrada a, Entrada b) => b.at.compareTo(a.at));
    await ref.read(entradaRepositoryProvider).replaceAll(all);
    state = all;
  }

  Future<void> clear() async {
    await ref.read(entradaRepositoryProvider).clear();
    state = <Entrada>[];
  }
}

final NotifierProvider<EntradasNotifier, List<Entrada>> entradasProvider =
    NotifierProvider<EntradasNotifier, List<Entrada>>(EntradasNotifier.new);

// ---------------------------------------------------------------------------
// Marca do freelancer (topo da proposta)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Preferências
// ---------------------------------------------------------------------------

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

class TelemetryNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(settingsRepositoryProvider).telemetryEnabled();

  Future<void> set(bool value) async {
    await ref.read(settingsRepositoryProvider).setTelemetry(value);
    state = value;
    // O opt-in vale NA HORA: quem desliga espera que pare agora, não no
    // próximo boot.
    await telemetry.setHabilitado(value);
  }
}

final NotifierProvider<TelemetryNotifier, bool> telemetryProvider =
    NotifierProvider<TelemetryNotifier, bool>(TelemetryNotifier.new);

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

// ---------------------------------------------------------------------------
// Pro
// ---------------------------------------------------------------------------

final Provider<EntitlementRepository> entitlementRepositoryProvider =
    Provider<EntitlementRepository>(
      (Ref ref) => EntitlementRepository(ref.watch(sharedPreferencesProvider)),
    );

class ProNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(entitlementRepositoryProvider).isPro();

  /// Concede o Pro. Hoje grava o entitlement local; quando a compra real pela
  /// loja for ligada, ela chama isto no sucesso — ver `09-HANDOFF`.
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

/// A ponte com o Play Billing. `onEntitled` liga o Pro quando a loja confirma a
/// compra — é o único caminho pra virar Pro agora (antes o botão concedia local,
/// e dava pra virar Pro sem pagar). Inicializado uma vez no boot (app.dart).
final Provider<BillingService> billingServiceProvider =
    Provider<BillingService>((Ref ref) {
      return BillingService(
        onEntitled: () => ref.read(proProvider.notifier).grant(),
        // Revoga quando a loja confirma (online) que a assinatura caiu — é o
        // que faz "cancelar" valer. Nunca revoga em falha/offline.
        onNotEntitled: () => ref.read(proProvider.notifier).revoke(),
      );
    });

// ---------------------------------------------------------------------------
// Backup e câmbio
// ---------------------------------------------------------------------------

final Provider<BackupService> backupServiceProvider = Provider<BackupService>(
  (Ref ref) => BackupService(
    ref.watch(areaRepositoryProvider),
    ref.watch(entradaRepositoryProvider),
    ref.watch(trabalhoRepositoryProvider),
    ref.watch(marcaRepositoryProvider),
  ),
);

final Provider<FxRepository> fxRepositoryProvider = Provider<FxRepository>(
  (Ref ref) => FxRepository(ref.watch(sharedPreferencesProvider)),
);

final Provider<FxService> fxServiceProvider = Provider<FxService>(
  (Ref ref) => FxService(ref.watch(fxRepositoryProvider)),
);
