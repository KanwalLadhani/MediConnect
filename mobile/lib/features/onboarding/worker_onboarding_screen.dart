import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_text_field.dart';
import '../../common/widgets/page_shell.dart';
import '../../models/service_category.dart';
import '../../services/profile_repository.dart';
import '../../services/service_request_repository.dart';
import '../../services/supabase_status.dart';

class WorkerOnboardingScreen extends StatefulWidget {
  const WorkerOnboardingScreen({super.key});

  @override
  State<WorkerOnboardingScreen> createState() => _WorkerOnboardingScreenState();
}

class _WorkerOnboardingScreenState extends State<WorkerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _cityController = TextEditingController(text: 'Karachi');
  final _serviceAreaController = TextEditingController();
  final _bioController = TextEditingController();
  final _basePriceController = TextEditingController(text: '1200');
  final _profileRepository = ProfileRepository();
  late final Future<List<ServiceCategory>> _categoriesFuture;

  String _workerType = 'nurse';
  ServiceCategory? _selectedService;
  _PickedDocument? _cnicDocument;
  _PickedDocument? _certificateDocument;
  _PickedDocument? _photoDocument;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = ServiceRequestRepository().fetchCategories();
  }

  @override
  void dispose() {
    _qualificationController.dispose();
    _experienceController.dispose();
    _cityController.dispose();
    _serviceAreaController.dispose();
    _bioController.dispose();
    _basePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument(String documentType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) {
      return;
    }

    final document = _PickedDocument(
      name: file.name,
      extension: file.extension ?? file.name.split('.').last,
      bytes: bytes,
    );

    setState(() {
      switch (documentType) {
        case 'cnic':
          _cnicDocument = document;
        case 'certificate':
          _certificateDocument = document;
        case 'profile_photo':
          _photoDocument = document;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!SupabaseStatus.isConfigured) {
      context.go('/verification-pending');
      return;
    }

    if (_cnicDocument == null || _certificateDocument == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.missingWorkerDocuments),
        ),
      );
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final workerId = await _profileRepository.createHealthWorker(
        userId: user.id,
        workerType: _workerType,
        qualification: _qualificationController.text.trim(),
        city: _cityController.text.trim(),
        serviceArea: _serviceAreaController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()),
        bio: _bioController.text.trim(),
      );

      await _uploadAndSaveDocument(
        workerId: workerId,
        documentType: 'cnic',
        document: _cnicDocument,
      );
      await _uploadAndSaveDocument(
        workerId: workerId,
        documentType: 'certificate',
        document: _certificateDocument,
      );
      await _uploadAndSaveDocument(
        workerId: workerId,
        documentType: 'profile_photo',
        document: _photoDocument,
      );

      final service = _selectedService;
      if (service != null) {
        await _profileRepository.upsertWorkerService(
          workerId: workerId,
          serviceCategoryId: service.id,
          basePricePkr: int.parse(_basePriceController.text.trim()),
        );
      }

      if (!mounted) {
        return;
      }
      context.go('/verification-pending');
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

  Future<void> _uploadAndSaveDocument({
    required String workerId,
    required String documentType,
    required _PickedDocument? document,
  }) async {
    if (document == null) {
      return;
    }

    final filePath = await _profileRepository.uploadWorkerDocumentFile(
      documentType: documentType,
      bytes: document.bytes,
      extension: document.extension,
    );

    await _profileRepository.addWorkerDocument(
      workerId: workerId,
      documentType: documentType,
      filePath: filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PageShell(
      title: l10n.workerVerificationTitle,
      subtitle: l10n.workerVerificationSubtitle,
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _workerType,
                decoration: InputDecoration(
                  labelText: l10n.workerType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'doctor', child: Text(l10n.doctor)),
                  DropdownMenuItem(value: 'nurse', child: Text(l10n.nurse)),
                  DropdownMenuItem(
                    value: 'male_nurse',
                    child: Text(l10n.maleNurse),
                  ),
                  DropdownMenuItem(
                    value: 'ot_technician',
                    child: Text(l10n.otTechnician),
                  ),
                  DropdownMenuItem(
                    value: 'dispenser',
                    child: Text(l10n.dispenser),
                  ),
                  DropdownMenuItem(
                    value: 'lab_collector',
                    child: Text(l10n.labCollector),
                  ),
                  DropdownMenuItem(value: 'other', child: Text(l10n.other)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _workerType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _qualificationController,
                label: l10n.qualification,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _experienceController,
                label: l10n.experienceYears,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _cityController,
                label: l10n.city,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _serviceAreaController,
                label: l10n.serviceArea,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<ServiceCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  final services = snapshot.data ?? [];
                  return DropdownButtonFormField<ServiceCategory>(
                    value: _selectedService,
                    decoration: InputDecoration(
                      labelText: l10n.primaryService,
                      border: const OutlineInputBorder(),
                    ),
                    items: services
                        .map(
                          (service) => DropdownMenuItem(
                            value: service,
                            child: Text(service.name),
                          ),
                        )
                        .toList(),
                    validator: (value) => value == null ? l10n.required : null,
                    onChanged: (value) {
                      setState(() => _selectedService = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _basePriceController,
                label: l10n.basePricePkr,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return l10n.enterValidPrice;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _bioController,
                label: l10n.bio,
                hint: l10n.bioHint,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _DocumentPickerField(
                document: _cnicDocument,
                title: l10n.cnic,
                subtitle: l10n.cnicUploadSubtitle,
                onPick: () => _pickDocument('cnic'),
              ),
              const SizedBox(height: 12),
              _DocumentPickerField(
                document: _certificateDocument,
                title: l10n.medicalLicenseOrCertificate,
                subtitle: l10n.certificateUploadSubtitle,
                onPick: () => _pickDocument('certificate'),
              ),
              const SizedBox(height: 12),
              _DocumentPickerField(
                document: _photoDocument,
                title: l10n.profilePhoto,
                subtitle: l10n.profilePhotoSubtitle,
                onPick: () => _pickDocument('profile_photo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: const Icon(Icons.verified_user_outlined),
          label: Text(
            _isSubmitting ? l10n.submitting : l10n.submitForVerification,
          ),
        ),
      ],
    );
  }
}

class _DocumentPickerField extends StatelessWidget {
  const _DocumentPickerField({
    required this.document,
    required this.title,
    required this.subtitle,
    required this.onPick,
  });

  final _PickedDocument? document;
  final String title;
  final String subtitle;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          document == null
              ? Icons.upload_file_outlined
              : Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(document?.name ?? subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onPick,
      ),
    );
  }
}

class _PickedDocument {
  const _PickedDocument({
    required this.name,
    required this.extension,
    required this.bytes,
  });

  final String name;
  final String extension;
  final Uint8List bytes;
}

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) {
    return l10n.required;
  }
  return null;
}
