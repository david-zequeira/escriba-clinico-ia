import 'package:flutter/material.dart';
import 'package:vionix_app_ui/vionix_app_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:escriba_clinico/core/config.dart';
import 'package:escriba_clinico/core/l10n_ext.dart';
import 'package:escriba_clinico/features/auth/state_management/auth_controller.dart';

/// Login del médico. SSO OIDC (si hay IdP configurado) + acceso de desarrollo.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController(text: 'medico.demo');
  final _passwordController = TextEditingController(text: 'demo');
  bool _loading = false;
  bool _ssoLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).loginDev(
            user: _userController.text,
            password: _passwordController.text,
          );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginSso() async {
    setState(() => _ssoLoading = true);
    try {
      await ref.read(authProvider.notifier).loginWithSso();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.loginFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _ssoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final formWidth = width >= 900 ? 400.0 : double.infinity;

    return AppPage(
      body: Center(
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: formWidth),
            child: GlassSurface(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [context.tokens.primary, context.tokens.primaryDark],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.medical_services_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text('Vionix', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    if (AppConfig.oidcConfigured) ...[
                      FilledButton.icon(
                        onPressed: _ssoLoading ? null : _loginSso,
                        icon: _ssoLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.shield_outlined, size: 20),
                        label: Text(l.signInWithSso),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l.devAccessLabel,
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _userController,
                      decoration: InputDecoration(
                        labelText: l.fieldUser,
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? l.validatorUser : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: l.fieldPassword,
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? l.validatorPassword : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(l.signIn),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l.devCredentialsHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
