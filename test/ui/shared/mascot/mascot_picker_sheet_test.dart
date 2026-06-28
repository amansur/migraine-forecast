import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:migraine_forecast/state/settings_provider.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_character.dart';
import 'package:migraine_forecast/ui/shared/mascot/mascot_picker_sheet.dart';

void main() {
  testWidgets('shows heading and 4 tiles; tapping persists + pops', (tester) async {
    // The 2×2 grid at 1:1 aspect ratio needs ~800 px of height; set a taller
    // viewport so every tile is on-screen and tappable in tests.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    MascotCharacter? saved;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        mascotCharacterProvider.overrideWith((ref) async => MascotCharacter.kitty),
        setMascotCharacterProvider.overrideWithValue((c) async => saved = c),
      ],
      child: const MaterialApp(home: Scaffold(body: MascotPickerSheet())),
    ));
    await tester.pump();

    expect(find.text('Choose your companion'), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-flower')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-kitty')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-bunny')), findsOneWidget);
    expect(find.byKey(const Key('mascot-tile-bee')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mascot-tile-bee')));
    await tester.pump();
    expect(saved, MascotCharacter.bee);
  });
}
