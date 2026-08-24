import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final light = appearance.themeMode == ThemeMode.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Görünüm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text('Koyu'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text('Açık'),
              icon: Icon(Icons.light_mode_outlined),
            ),
          ],
          selected: {light ? ThemeMode.light : ThemeMode.dark},
          onSelectionChanged: (next) {
            ref.read(appearanceControllerProvider).setThemeMode(next.first);
          },
        ),
      ],
    );
  }
}
