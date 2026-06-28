import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/mascot_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every mascot SVG is present in the bundle and parses', () async {
    for (final path in allMascotAssetPaths()) {
      final raw = await rootBundle.loadString(path);
      expect(raw.contains('<svg'), isTrue, reason: '$path missing <svg>');
      // Throws if the SVG is malformed.
      await vg.loadPicture(SvgStringLoader(raw), null);
    }
  });
}
