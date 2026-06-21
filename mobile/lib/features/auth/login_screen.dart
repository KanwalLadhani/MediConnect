import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/page_shell.dart';
import '../../models/user_role.dart';
import '../../services/auth_repository.dart';
import '../../services/profile_repository.dart';
import '../../services/supabase_status.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepository();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!SupabaseStatus.isConfigured) {
      context.go('/dashboard/patient');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _authRepository.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = response.user;
      final role = await _profileRepository.fetchCurrentRole();

      if (!mounted) {
        return;
      }

      if (user == null || role == null) {
        context.go('/role');
        return;
      }

      if (role == UserRole.patient || role == UserRole.healthWorker) {
        context.go(await _profileRepository.resolveCurrentHomePath());
        return;
      }

      context.go('/dashboard/patient');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showProviderSetupPending(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.authProviderSetupPending)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PageShell(
      title: l10n.welcomeBack,
      subtitle: l10n.loginSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _emailController,
                label: l10n.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: l10n.password,
                obscureText: true,
                validator: (value) => _required(value, l10n),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSubmitting ? null : _login,
          child: Text(_isSubmitting ? l10n.loggingIn : l10n.login),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showProviderSetupPending(l10n),
          icon: const Icon(Icons.sms_outlined),
          label: Text(l10n.continueWithOtp),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showProviderSetupPending(l10n),
          icon: const Icon(Icons.g_mobiledata),
          label: Text(l10n.continueWithGoogle),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/role'),
          child: Text(l10n.createNewAccount),
        ),
      ],
    );
  }
}

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.required;
  }
  return null;
}
