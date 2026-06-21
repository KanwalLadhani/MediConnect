import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import 'supabase_status.dart';

class ProfileRepository {
  Future<void> upsertProfile({
    required String userId,
    required UserRole role,
    required String fullName,
    required String phone,
    String? email,
    String preferredLanguage = 'en',
  }) async {
    final validationError = profileValidationError(
      userId: userId,
      fullName: fullName,
      phone: phone,
      preferredLanguage: preferredLanguage,
    );
    if (validationError != null) {
      throw ArgumentError(profileValidationMessage(validationError));
    }

    await SupabaseStatus.client.from('profiles').upsert({
      'id': userId.trim(),
      'role': role.value,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'email': _trimmedOrNull(email),
      'preferred_language': preferredLanguage.trim(),
    });
  }

  Future<UserRole?> fetchCurrentRole() async {
    if (!SupabaseStatus.isConfigured) {
      return UserRole.patient;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await SupabaseStatus.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = profile?['role'] as String?;
    return role == null ? null : UserRole.fromValue(role);
  }

  Future<String> resolveCurrentHomePath() async {
    if (!SupabaseStatus.isConfigured) {
      return '/dashboard/patient';
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return '/login';
    }

    final profile = await SupabaseStatus.client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = profile?['role'] as String?;
    if (role == UserRole.patient.value) {
      return await hasPatientRecord(user.id)
          ? '/dashboard/patient'
          : '/onboarding/patient';
    }

    if (role == UserRole.healthWorker.value) {
      final worker = await fetchCurrentWorkerStatus();
      if (worker == null) {
        return '/onboarding/worker';
      }
      return worker == 'approved'
          ? '/dashboard/worker'
          : '/verification-pending';
    }

    return '/role';
  }

  Future<String?> fetchCurrentWorkerStatus() async {
    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final worker = await SupabaseStatus.client
        .from('health_workers')
        .select('verification_status')
        .eq('user_id', user.id)
        .maybeSingle();

    return worker?['verification_status'] as String?;
  }

  Future<Map<String, dynamic>?> fetchCurrentWorkerVerification() async {
    if (!SupabaseStatus.isConfigured) {
      return {
        'verification_status': 'pending',
        'rejection_reason': null,
      };
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return SupabaseStatus.client
        .from('health_workers')
        .select('verification_status, rejection_reason')
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> fetchCurrentProfile() async {
    if (!SupabaseStatus.isConfigured) {
      return {
        'id': 'demo-user',
        'role': UserRole.patient.value,
        'full_name': 'Demo Patient',
        'phone': '+92 300 0000000',
        'email': 'demo.patient@mediconnect.test',
        'preferred_language': 'en',
      };
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    return SupabaseStatus.client
        .from('profiles')
        .select('id, role, full_name, phone, email, preferred_language')
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<void> updatePreferredLanguage(String languageCode) async {
    if (preferredLanguageError(languageCode) != null) {
      throw ArgumentError('Choose English or Urdu.');
    }

    if (!SupabaseStatus.isConfigured) {
      return;
    }

    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await SupabaseStatus.client
        .from('profiles')
        .update({'preferred_language': languageCode.trim()}).eq('id', user.id);
  }

  Future<bool> hasPatientRecord(String userId) async {
    final patient = await SupabaseStatus.client
        .from('patients')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return patient != null;
  }

  Future<bool> hasWorkerRecord(String userId) async {
    final worker = await SupabaseStatus.client
        .from('health_workers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    return worker != null;
  }

  Future<void> createPatient({
    required String userId,
    required String city,
    String? address,
    String? gender,
    String? emergencyContactPhone,
    String? medicalNotes,
  }) async {
    final validationError = patientProfileValidationError(
      userId: userId,
      city: city,
      address: address,
    );
    if (validationError != null) {
      throw ArgumentError(patientProfileValidationMessage(validationError));
    }

    await SupabaseStatus.client.from('patients').upsert(
      {
        'user_id': userId.trim(),
        'city': city.trim(),
        'address': _trimmedOrNull(address),
        'gender': _trimmedOrNull(gender),
        'emergency_contact_phone': _trimmedOrNull(emergencyContactPhone),
        'medical_notes': _trimmedOrNull(medicalNotes),
      },
      onConflict: 'user_id',
    );
  }

  Future<String> createHealthWorker({
    required String userId,
    required String workerType,
    required String qualification,
    required String city,
    String? serviceArea,
    int? experienceYears,
    String? bio,
  }) async {
    final validationError = workerProfileValidationError(
      userId: userId,
      workerType: workerType,
      qualification: qualification,
      city: city,
      experienceYears: experienceYears,
    );
    if (validationError != null) {
      throw ArgumentError(workerProfileValidationMessage(validationError));
    }

    final worker = await SupabaseStatus.client
        .from('health_workers')
        .upsert(
          {
            'user_id': userId.trim(),
            'worker_type': workerType.trim(),
            'qualification': qualification.trim(),
            'city': city.trim(),
            'service_area': serviceArea?.trim(),
            'experience_years': experienceYears,
            'bio': bio?.trim(),
            'verification_status': 'pending',
            'rejection_reason': null,
          },
          onConflict: 'user_id',
        )
        .select('id')
        .single();

    await SupabaseStatus.client.from('wallets').upsert(
      {
        'worker_id': worker['id'],
      },
      onConflict: 'worker_id',
    );

    return worker['id'] as String;
  }

  Future<void> addWorkerDocument({
    required String workerId,
    required String documentType,
    required String filePath,
  }) async {
    if (filePath.trim().isEmpty) {
      return;
    }

    await SupabaseStatus.client.from('worker_documents').insert({
      'worker_id': workerId,
      'document_type': documentType,
      'file_path': filePath.trim(),
    });
  }

  Future<String> uploadWorkerDocumentFile({
    required String documentType,
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = SupabaseStatus.client.auth.currentUser;
    if (user == null) {
      throw StateError('Please log in to upload documents.');
    }

    final normalizedExtension = normalizedWorkerDocumentExtension(extension);
    if (workerDocumentExtensionError(normalizedExtension) != null) {
      throw ArgumentError('Unsupported document type.');
    }

    final path =
        '${user.id}/$documentType/${DateTime.now().millisecondsSinceEpoch}.$normalizedExtension';

    return SupabaseStatus.client.storage.from('worker-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(normalizedExtension),
          ),
        );
  }

  Future<void> upsertWorkerService({
    required String workerId,
    required String serviceCategoryId,
    required int basePricePkr,
  }) async {
    final validationError = workerServiceValidationError(
      workerId: workerId,
      serviceCategoryId: serviceCategoryId,
      basePricePkr: basePricePkr,
    );
    if (validationError != null) {
      throw ArgumentError(workerServiceValidationMessage(validationError));
    }

    await SupabaseStatus.client.from('worker_services').upsert(
      {
        'worker_id': workerId.trim(),
        'service_category_id': serviceCategoryId.trim(),
        'base_price_pkr': basePricePkr,
        'is_active': true,
      },
      onConflict: 'worker_id,service_category_id',
    );
  }
}

ProfileValidationError? profileValidationError({
  required String userId,
  required String fullName,
  required String phone,
  required String preferredLanguage,
}) {
  if (userId.trim().isEmpty) {
    return ProfileValidationError.missingUser;
  }
  if (fullName.trim().isEmpty) {
    return ProfileValidationError.missingFullName;
  }
  if (phone.trim().isEmpty) {
    return ProfileValidationError.missingPhone;
  }
  if (preferredLanguageError(preferredLanguage) != null) {
    return ProfileValidationError.unsupportedLanguage;
  }

  return null;
}

String profileValidationMessage(ProfileValidationError error) {
  return switch (error) {
    ProfileValidationError.missingUser => 'Please log in again.',
    ProfileValidationError.missingFullName => 'Enter full name.',
    ProfileValidationError.missingPhone => 'Enter phone number.',
    ProfileValidationError.unsupportedLanguage => 'Choose English or Urdu.',
  };
}

PreferredLanguageError? preferredLanguageError(String? languageCode) {
  if (languageCode == null || languageCode.trim().isEmpty) {
    return PreferredLanguageError.missing;
  }
  if (!{'en', 'ur'}.contains(languageCode.trim())) {
    return PreferredLanguageError.unsupported;
  }

  return null;
}

enum ProfileValidationError {
  missingUser,
  missingFullName,
  missingPhone,
  unsupportedLanguage,
}

enum PreferredLanguageError {
  missing,
  unsupported,
}

PatientProfileValidationError? patientProfileValidationError({
  required String userId,
  required String city,
  String? address,
}) {
  if (userId.trim().isEmpty) {
    return PatientProfileValidationError.missingUser;
  }
  if (address == null || address.trim().isEmpty) {
    return PatientProfileValidationError.missingAddress;
  }
  if (city.trim().isEmpty) {
    return PatientProfileValidationError.missingCity;
  }

  return null;
}

String patientProfileValidationMessage(PatientProfileValidationError error) {
  return switch (error) {
    PatientProfileValidationError.missingUser => 'Please log in again.',
    PatientProfileValidationError.missingAddress => 'Enter address.',
    PatientProfileValidationError.missingCity => 'Enter city.',
  };
}

enum PatientProfileValidationError {
  missingUser,
  missingAddress,
  missingCity,
}

WorkerProfileValidationError? workerProfileValidationError({
  required String userId,
  required String workerType,
  required String qualification,
  required String city,
  int? experienceYears,
}) {
  if (userId.trim().isEmpty) {
    return WorkerProfileValidationError.missingUser;
  }
  if (workerType.trim().isEmpty) {
    return WorkerProfileValidationError.missingWorkerType;
  }
  if (qualification.trim().isEmpty) {
    return WorkerProfileValidationError.missingQualification;
  }
  if (city.trim().isEmpty) {
    return WorkerProfileValidationError.missingCity;
  }
  if (experienceYears != null && experienceYears < 0) {
    return WorkerProfileValidationError.invalidExperience;
  }

  return null;
}

String workerProfileValidationMessage(WorkerProfileValidationError error) {
  return switch (error) {
    WorkerProfileValidationError.missingUser => 'Please log in again.',
    WorkerProfileValidationError.missingWorkerType => 'Choose worker type.',
    WorkerProfileValidationError.missingQualification => 'Enter qualification.',
    WorkerProfileValidationError.missingCity => 'Enter city.',
    WorkerProfileValidationError.invalidExperience =>
      'Enter valid experience years.',
  };
}

enum WorkerProfileValidationError {
  missingUser,
  missingWorkerType,
  missingQualification,
  missingCity,
  invalidExperience,
}

WorkerServiceValidationError? workerServiceValidationError({
  required String workerId,
  required String serviceCategoryId,
  required int basePricePkr,
}) {
  if (workerId.trim().isEmpty) {
    return WorkerServiceValidationError.missingWorker;
  }
  if (serviceCategoryId.trim().isEmpty) {
    return WorkerServiceValidationError.missingServiceCategory;
  }
  if (basePricePkr <= 0) {
    return WorkerServiceValidationError.invalidBasePrice;
  }

  return null;
}

String workerServiceValidationMessage(WorkerServiceValidationError error) {
  return switch (error) {
    WorkerServiceValidationError.missingWorker => 'Worker profile is missing.',
    WorkerServiceValidationError.missingServiceCategory => 'Choose a service.',
    WorkerServiceValidationError.invalidBasePrice => 'Enter a valid price.',
  };
}

enum WorkerServiceValidationError {
  missingWorker,
  missingServiceCategory,
  invalidBasePrice,
}

String normalizedWorkerDocumentExtension(String? extension) {
  return (extension ?? '').replaceAll('.', '').trim().toLowerCase();
}

WorkerDocumentExtensionError? workerDocumentExtensionError(String? extension) {
  final normalizedExtension = normalizedWorkerDocumentExtension(extension);
  if (!{'jpg', 'jpeg', 'png', 'pdf'}.contains(normalizedExtension)) {
    return WorkerDocumentExtensionError.unsupported;
  }

  return null;
}

enum WorkerDocumentExtensionError {
  unsupported,
}

String _contentTypeForExtension(String extension) {
  return switch (extension) {
    'png' => 'image/png',
    'pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
