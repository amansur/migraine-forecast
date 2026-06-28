import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/theme.dart';
import '../../../state/settings_provider.dart';
import 'mascot_character.dart';

class MascotPickerSheet extends ConsumerWidget {
  const MascotPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const MascotPickerSheet(),
    );
  }

  static const _labels = <MascotCharacter, String>{
    MascotCharacter.flower: 'Flower',
    MascotCharacter.kitty: 'Kitty',
    MascotCharacter.bunny: 'Bunny',
    MascotCharacter.bee: 'Bee',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(mascotCharacterProvider).asData?.value ?? kDefaultMascotCharacter;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose your companion', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
              children: [
                for (final c in MascotCharacter.values)
                  _MascotTile(
                    character: c,
                    label: _labels[c]!,
                    selected: c == selected,
                    onTap: () async {
                      await ref.read(setMascotCharacterProvider)(c);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotTile extends StatelessWidget {
  final MascotCharacter character;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MascotTile({
    required this.character,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('mascot-tile-${character.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? BrandColors.sage : Colors.transparent,
              width: 3,
            ),
            color: BrandColors.ivory,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SvgPicture.asset(
                  mascotAssetPath(character, RiskBand.low),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
