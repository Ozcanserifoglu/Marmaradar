import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/features/profile/vehicle_models.dart';

class UsernameSection extends ConsumerStatefulWidget {
  const UsernameSection({super.key});

  @override
  ConsumerState<UsernameSection> createState() => _UsernameSectionState();
}

class _UsernameSectionState extends ConsumerState<UsernameSection> {
  late final TextEditingController _controller;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(vehicleCustomizationControllerProvider).username ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final value = _controller.text.trim().toLowerCase();
    if (!isValidUsername(value)) {
      setState(() {
        _localError = 'Kullanıcı adı 3–20 karakter olmalı (a-z, 0-9, _).';
      });
      return;
    }
    setState(() => _localError = null);

    final err = await ref
        .read(vehicleCustomizationControllerProvider)
        .saveUsername(value);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı adı kaydedildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(vehicleCustomizationControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(vehicleCustomizationControllerProvider, (prev, next) {
      final nextName = next.username ?? '';
      if (nextName.isNotEmpty &&
          _controller.text != nextName &&
          !next.savingUsername) {
        _controller.value = TextEditingValue(
          text: nextName,
          selection: TextSelection.collapsed(offset: nextName.length),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanıcı Adı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sıralamada görünecek adınız. Boş bırakırsanız e-postanızın maskelenmiş hali kullanılır.',
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          enabled: !vehicle.savingUsername,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            LengthLimitingTextInputFormatter(20),
            _LowerCaseTextFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'ornek_surucu',
            errorText: _localError,
            helperText: 'Sadece a-z, 0-9 ve _ · 3–20 karakter',
          ),
          onChanged: (_) {
            if (_localError != null) setState(() => _localError = null);
          },
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: vehicle.savingUsername ? null : _save,
            child: vehicle.savingUsername
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kullanıcı Adını Kaydet'),
          ),
        ),
      ],
    );
  }
}

class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    if (lower == newValue.text) return newValue;
    return TextEditingValue(
      text: lower,
      selection: newValue.selection,
    );
  }
}
