import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_text_field.dart';
import '../../models/service_category.dart';
import '../../services/service_request_repository.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({
    required this.category,
    super.key,
  });

  final ServiceCategory category;

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _repository = ServiceRequestRepository();
  final _imagePicker = ImagePicker();

  Uint8List? _imageBytes;
  String? _imageExtension;
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadLocationDefaults();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationDefaults() async {
    final defaults = await _repository.fetchCurrentPatientLocationDefaults();
    if (!mounted || defaults == null) {
      return;
    }

    if (_addressController.text.trim().isEmpty && defaults.address.isNotEmpty) {
      _addressController.text = defaults.address;
    }
    if (_cityController.text.trim().isEmpty) {
      _cityController.text = defaults.city;
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageExtension = image.name.split('.').last;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      final location = await _repository.fetchCurrentGpsLocationDefaults();
      if (!mounted) {
        return;
      }

      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = location.address;
        }
        if (_cityController.text.trim().isEmpty) {
          _cityController.text = location.city;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _repository.createRequest(
        category: widget.category,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        imageBytes: _imageBytes,
        imageExtension: _imageExtension,
      );

      if (!mounted) {
        return;
      }

      context.go('/services/workers', extra: result);
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.category.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.category.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.category.description!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.tellWorkersNeed,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.tellWorkersNeedSubtitle,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _StepLabel(number: '1', label: l10n.patientNeed),
              const SizedBox(height: 10),
              AppTextField(
                controller: _descriptionController,
                label: l10n.issueDetails,
                hint: l10n.issueDetailsHint,
                maxLines: 5,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              Material(
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: Icon(
                    _imageBytes == null
                        ? Icons.add_photo_alternate_outlined
                        : Icons.check_circle_outline,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    _imageBytes == null
                        ? l10n.addOptionalIssuePhoto
                        : l10n.issuePhotoSelected,
                  ),
                  subtitle: Text(l10n.issuePhotoUseful),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(height: 24),
              _StepLabel(number: '2', label: l10n.serviceLocation),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isLocating ? null : _useCurrentLocation,
                icon: _isLocating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _latitude == null
                            ? Icons.my_location_outlined
                            : Icons.check_circle_outline,
                      ),
                label: Text(
                  _isLocating
                      ? 'Checking current location...'
                      : _latitude == null
                          ? 'Use current location'
                          : 'Current location selected',
                  textAlign: TextAlign.center,
                ),
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Workers will be sorted by distance from this GPS location.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              AppTextField(
                controller: _addressController,
                label: l10n.address,
                hint: l10n.addressHint,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _cityController,
                label: l10n.city,
                validator: (value) => _required(value, l10n),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.approvedWorkersOnly,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isSubmitting ? l10n.findingWorkers : l10n.findWorkers,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.label,
  });

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
