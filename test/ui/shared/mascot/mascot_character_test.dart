import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/mascot_character.dart';

void main() {
  test('asset path is character_band.svg under assets/mascots', () {
    expect(
      mascotAssetPath(MascotCharacter.bee, RiskBand.veryHigh),
      'assets/mascots/bee_veryHigh.svg',
    );
    expect(
      mascotAssetPath(MascotCharacter.flower, RiskBand.low),
      'assets/mascots/flower_low.svg',
    );
  });

  test('allMascotAssetPaths has 16 unique entries', () {
    final paths = allMascotAssetPaths();
    expect(paths.length, 16);
    expect(paths.toSet().length, 16);
    expect(paths, contains('assets/mascots/kitty_moderate.svg'));
  });

  test('default character is bee', () {
    expect(kDefaultMascotCharacter, MascotCharacter.bee);
  });
}
