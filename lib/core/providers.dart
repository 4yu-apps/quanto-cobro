import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'billing/entitlement.dart';
import 'data/backup_service.dart';
import 'data/profile_repository.dart';
import 'model/perfil.dart';
import 'settings/settings_repository.dart';

/// Injetado em main() via override (prefs já carregado no boot).
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) => throw UnimplementedError('override em main()'));

final Provider<ProfileRepository> profileRepositoryProvider = Provider<ProfileRepository>(
  (Ref ref) => PrefsProfileRepository(ref.watch(sharedPreferencesProvider)),
);

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>(
  (Ref ref) => SettingsRepository(ref.watch(sharedPreferencesProvider)),
);

/// Estado do perfil — três ramos explícitos (matriz de estados do Blueprint
/// §5.9): vazio (nunca calculou) · pronto · erro (dado salvo corrompido).
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

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => _read();

  ProfileState _read() {
    try {
      final Perfil? p = ref.read(profileRepositoryProvider).loadSync();
      return p == null ? const ProfileEmpty() : ProfileReady(p);
    } catch (_) {
      // Dado salvo corrompido: erro distinto de "vazio" — o Painel oferece refazer.
      return const ProfileError('Não consegui carregar seu cálculo. Vamos refazer?');
    }
  }

  Future<void> save(Perfil perfil) async {
    await ref.read(profileRepositoryProvider).save(perfil);
    state = ProfileReady(perfil);
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = const ProfileEmpty();
  }
}

final NotifierProvider<ProfileNotifier, ProfileState> profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

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
  (Ref ref) => BackupService(ref.watch(profileRepositoryProvider)),
);

// ---- Entitlement Pro ----
final Provider<EntitlementRepository> entitlementRepositoryProvider =
    Provider<EntitlementRepository>(
  (Ref ref) => EntitlementRepository(ref.watch(sharedPreferencesProvider)),
);

class ProNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(entitlementRepositoryProvider).isPro();

  /// Concede o Pro. Hoje grava o entitlement local; quando a compra real
  /// (in_app_purchase) for ligada com os IDs da Play, ela chama isto no sucesso.
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
