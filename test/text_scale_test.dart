import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
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
}
