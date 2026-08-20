import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';
import 'package:radar_alert/data/api/radar_api_client.dart';

/// Returns true if the reset email request completed successfully.
Future<bool> showForgotPasswordDialog(
  BuildContext context,
  WidgetRef ref, {
  String initialEmail = '',
}) {
  final emailCtrl = TextEditingController(text: initialEmail.trim());
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      var sending = false;
      String? error;
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final email = emailCtrl.text.trim();
            if (email.isEmpty || !email.contains('@')) {
              setState(() => error = 'Geçerli bir e-posta adresi girin.');
              return;
            }
            setState(() {
              sending = true;
              error = null;
            });
            try {
              await ref
                  .read(authControllerProvider)
                  .requestPasswordReset(email);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(true);
              }
            } on ApiException catch (e) {
              setState(() {
                sending = false;
                error = e.isNetworkError || e.statusCode == 404
                    ? 'Sunucuya ulaşılamadı. Lütfen tekrar deneyin.'
                    : e.message;
              });
            } catch (_) {
              setState(() {
                sending = false;
                error = 'Sunucuya ulaşılamadı. Lütfen tekrar deneyin.';
              });
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Şifremi unuttum'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'E-posta adresinizi girin. Varsa şifre sıfırlama bağlantısını göndeririz.',
                  style: TextStyle(color: AppColors.whiteMuted, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  autofocus: true,
                  enabled: !sending,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => sending ? null : submit(),
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: sending ? null : submit,
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Gönder'),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(emailCtrl.dispose).then((value) => value ?? false);
}
