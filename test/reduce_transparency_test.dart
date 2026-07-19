import 'package:flutter_test/flutter_test.dart';
import 'package:quantocobro/core/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reduceTransparency default é false e persiste', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SettingsRepository repo = SettingsRepository(
      await SharedPreferences.getInstance(),
    );
    expect(repo.reduceTransparency(), isFalse);
    await repo.setReduceTransparency(true);
    expect(repo.reduceTransparency(), isTrue);
  });
}
