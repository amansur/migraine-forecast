import 'package:domain/domain.dart';

/// The four selectable mascot characters. Each has 4 SVG variants, one per
/// [RiskBand], living at `assets/mascots/<character>_<band>.svg`.
enum MascotCharacter { flower, kitty, bunny, bee }

/// Default mascot on a fresh install.
const MascotCharacter kDefaultMascotCharacter = MascotCharacter.kitty;

/// Resolves the SVG asset path for a given character + risk band.
String mascotAssetPath(MascotCharacter character, RiskBand band) =>
    'assets/mascots/${character.name}_${band.name}.svg';

/// All 16 mascot SVG asset paths (used for startup pre-caching).
List<String> allMascotAssetPaths() => [
      for (final c in MascotCharacter.values)
        for (final b in RiskBand.values) mascotAssetPath(c, b),
    ];
