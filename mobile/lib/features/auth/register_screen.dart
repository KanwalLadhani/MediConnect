import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/page_shell.dart';
import '../../models/user_role.dart';
import '../../services/auth_repository.dart';
import '../../services/supabase_status.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    required this.role,
    super.key,
  });

  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isSubmitting = false;

  bool get _isWorker => widget.role == 'health_worker';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!SupabaseStatus.isConfigured) {
      context.go(_isWorker ? '/onboarding/worker' : '/onboarding/patient');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authRepository.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: UserRole.fromValue(widget.role),
      );

      if (!mounted) {
        return;
      }
      context.go(_isWorker ? '/onboarding/worker' : '/onboarding/patient');
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
    final title = _isWorker ? l10n.joinWorkerTitle : l10n.createPatientAccount;
    final subtitle =
        _isWorker ? l10n.workerRegisterSubtitle : l10n.patientRegisterSubtitle;

    return PageShell(
      title: title,
      subtitle: subtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _fullNameController,
                label: l10n.fullName,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneController,
                label: l10n.phoneNumber,
                hint: '+92 300 0000000',
                keyboardType: TextInputType.phone,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
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
                validator: (value) {
                  if ((value ?? '').length < 6) {
                    return l10n.passwordTooShort;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isSubmitting ? null : _createAccount,
          child: Text(_isSubmitting ? l10n.creating : l10n.createAccount),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showProviderSetupPending(l10n),
          icon: const Icon(Icons.g_mobiledata),
          label: Text(l10n.continueWithGoogle),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(l10n.alreadyHaveAccount),
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
