import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:radar_alert/app.dart';
import 'package:radar_alert/core/theme/app_theme.dart';

Future<bool> showAuthModal(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AuthScreen(asModal: true),
    ),
  );
  return result ?? false;
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.asModal = false});

  final bool asModal;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _registerMode = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authControllerProvider);
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final ok = _registerMode
        ? await auth.register(email, password)
        : await auth.login(email, password);
    if (!ok || !mounted) return;
    if (widget.asModal) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: widget.asModal
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: auth.isBusy
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'MARMARADAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _registerMode ? 'Hesap oluştur' : 'Giriş yap',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sürüş kayıtlarını kaydetmek için hesabınıza giriş yapın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.whiteMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      auth.error!,
                      style: const TextStyle(color: AppColors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: auth.isBusy ? null : _submit,
                    child: auth.isBusy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_registerMode ? 'Kayıt ol' : 'Giriş yap'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: auth.isBusy
                        ? null
                        : () {
                            auth.clearError();
                            setState(() => _registerMode = !_registerMode);
                          },
                    child: Text(
                      _registerMode
                          ? 'Zaten hesabın var mı? Giriş yap'
                          : 'Hesabın yok mu? Kayıt ol',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
