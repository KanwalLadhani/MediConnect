import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/page_shell.dart';
import '../../services/profile_repository.dart';
import '../../services/supabase_status.dart';

class PatientOnboardingScreen extends StatefulWidget {
  const PatientOnboardingScreen({super.key});

  @override
  State<PatientOnboardingScreen> createState() =>
      _PatientOnboardingScreenState();
}

class _PatientOnboardingScreenState extends State<PatientOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Karachi');
  final _genderController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _profileRepository = ProfileRepository();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _genderController.dispose();
    _emergencyPhoneController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!SupabaseStatus.isConfigured) {
      context.go('/dashboard/patient');
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _profileRepository.createPatient(
        userId: user.id,
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        gender: _genderController.text.trim(),
        emergencyContactPhone: _emergencyPhoneController.text.trim(),
        medicalNotes: _medicalNotesController.text.trim(),
      );

      if (!mounted) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.patientDetails,
      subtitle: l10n.patientDetailsSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _addressController,
                label: l10n.address,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _cityController,
                label: l10n.city,
                hint: l10n.cityHint,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _genderController,
                label: l10n.gender,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emergencyPhoneController,
                label: l10n.emergencyContactPhone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _medicalNotesController,
                label: l10n.medicalNotes,
                hint: l10n.medicalNotesHint,
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: const Icon(Icons.location_on_outlined),
          label: Text(
            _isSubmitting ? l10n.saving : l10n.allowLocationAndContinue,
          ),
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
