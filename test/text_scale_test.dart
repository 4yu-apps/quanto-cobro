import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
import 'package:quantocobro/core/ui/text_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('textScale default 1.0 e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository repo = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repo.textScale(), 1.0);
    await repo.setTextScale(1.15);
    expect(repo.textScale(), 1.15);
  });

  test('effectiveTextScale multiplica sistema x app', () {
    expect(effectiveTextScale(1.0, 1.15), closeTo(1.15, 1e-9));
    expect(effectiveTextScale(1.3, 1.15), closeTo(1.495, 1e-9));
  });
  test('effectiveTextScale clampa em [0.85, 2.0]', () {
    expect(effectiveTextScale(2.0, 1.30), 2.0); // teto
    expect(effectiveTextScale(0.5, 0.90), 0.85); // piso
  });
  test('4 níveis, valores corretos', () {
    expect(kTextScaleLevels.map((TextScaleLevel l) => l.value).toList(), <
      double
    >[0.90, 1.00, 1.15, 1.30]);
  });
}
