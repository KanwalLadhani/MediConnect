import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/models/user_role.dart';
import 'package:mediconnect/services/profile_repository.dart';

void main() {
  group('profileValidationError', () {
    test('allows valid shared profile fields', () {
      expect(
        profileValidationError(
          userId: ' user-id ',
          fullName: ' Demo User ',
          phone: ' +92 300 0000000 ',
          preferredLanguage: 'en',
        ),
        isNull,
      );
      expect(
        profileValidationError(
          userId: 'user-id',
          fullName: 'Demo User',
          phone: '+92 300 0000000',
          preferredLanguage: 'ur',
        ),
        isNull,
      );
    });

    test('rejects missing user, name, phone, and unsupported language', () {
      expect(
        profileValidationError(
          userId: ' ',
          fullName: 'Demo User',
          phone: '+92 300 0000000',
          preferredLanguage: 'en',
        ),
        ProfileValidationError.missingUser,
      );
      expect(
        profileValidationError(
          userId: 'user-id',
          fullName: ' ',
          phone: '+92 300 0000000',
          preferredLanguage: 'en',
        ),
        ProfileValidationError.missingFullName,
      );
      expect(
        profileValidationError(
          userId: 'user-id',
          fullName: 'Demo User',
          phone: ' ',
          preferredLanguage: 'en',
        ),
        ProfileValidationError.missingPhone,
      );
      expect(
        profileValidationError(
          userId: 'user-id',
          fullName: 'Demo User',
          phone: '+92 300 0000000',
          preferredLanguage: 'fr',
        ),
        ProfileValidationError.unsupportedLanguage,
      );
    });

    test('upsertProfile blocks invalid fields before Supabase path', () {
      expect(
        () => ProfileRepository().upsertProfile(
          userId: 'user-id',
          role: UserRole.patient,
          fullName: '',
          phone: '+92 300 0000000',
        ),
        throwsArgumentError,
      );
    });
  });

  group('preferredLanguageError', () {
    test('allows English and Urdu locale codes', () {
      expect(preferredLanguageError('en'), isNull);
      expect(preferredLanguageError('ur'), isNull);
      expect(preferredLanguageError(' ur '), isNull);
    });

    test('rejects missing and unsupported locale codes', () {
      expect(preferredLanguageError(null), PreferredLanguageError.missing);
      expect(preferredLanguageError(''), PreferredLanguageError.missing);
      expect(preferredLanguageError('fr'), PreferredLanguageError.unsupported);
    });

    test('updatePreferredLanguage blocks invalid language before Supabase path',
        () {
      expect(
        () => ProfileRepository().updatePreferredLanguage('fr'),
        throwsArgumentError,
      );
    });
  });

  group('patientProfileValidationError', () {
    test('allows valid patient profile fields after trimming', () {
      expect(
        patientProfileValidationError(
          userId: ' user-id ',
          address: ' House 12, Block 4 ',
          city: ' Karachi ',
        ),
        isNull,
      );
    });

    test('rejects missing user, address, and city', () {
      expect(
        patientProfileValidationError(
          userId: ' ',
          address: 'House 12',
          city: 'Karachi',
        ),
        PatientProfileValidationError.missingUser,
      );
      expect(
        patientProfileValidationError(
          userId: 'user-id',
          address: ' ',
          city: 'Karachi',
        ),
        PatientProfileValidationError.missingAddress,
      );
      expect(
        patientProfileValidationError(
          userId: 'user-id',
          address: 'House 12',
          city: ' ',
        ),
        PatientProfileValidationError.missingCity,
      );
    });

    test('createPatient blocks invalid fields before Supabase path', () {
      expect(
        () => ProfileRepository().createPatient(
          userId: 'user-id',
          address: '',
          city: 'Karachi',
        ),
        throwsArgumentError,
      );
    });
  });

  group('workerProfileValidationError', () {
    test('allows valid worker verification profile fields', () {
      expect(
        workerProfileValidationError(
          userId: ' user-id ',
          workerType: ' nurse ',
          qualification: ' Registered Nurse ',
          city: ' Karachi ',
          experienceYears: 4,
        ),
        isNull,
      );
      expect(
        workerProfileValidationError(
          userId: 'user-id',
          workerType: 'nurse',
          qualification: 'Registered Nurse',
          city: 'Karachi',
        ),
        isNull,
      );
    });

    test('rejects missing required worker profile fields', () {
      expect(
        workerProfileValidationError(
          userId: ' ',
          workerType: 'nurse',
          qualification: 'Registered Nurse',
          city: 'Karachi',
        ),
        WorkerProfileValidationError.missingUser,
      );
      expect(
        workerProfileValidationError(
          userId: 'user-id',
          workerType: ' ',
          qualification: 'Registered Nurse',
          city: 'Karachi',
        ),
        WorkerProfileValidationError.missingWorkerType,
      );
      expect(
        workerProfileValidationError(
          userId: 'user-id',
          workerType: 'nurse',
          qualification: ' ',
          city: 'Karachi',
        ),
        WorkerProfileValidationError.missingQualification,
      );
      expect(
        workerProfileValidationError(
          userId: 'user-id',
          workerType: 'nurse',
          qualification: 'Registered Nurse',
          city: ' ',
        ),
        WorkerProfileValidationError.missingCity,
      );
    });

    test('rejects negative experience years', () {
      expect(
        workerProfileValidationError(
          userId: 'user-id',
          workerType: 'nurse',
          qualification: 'Registered Nurse',
          city: 'Karachi',
          experienceYears: -1,
        ),
        WorkerProfileValidationError.invalidExperience,
      );
    });

    test('createHealthWorker blocks invalid fields before Supabase path', () {
      expect(
        () => ProfileRepository().createHealthWorker(
          userId: 'user-id',
          workerType: 'nurse',
          qualification: '',
          city: 'Karachi',
        ),
        throwsArgumentError,
      );
    });
  });

  group('workerServiceValidationError', () {
    test('allows valid worker service pricing', () {
      expect(
        workerServiceValidationError(
          workerId: ' worker-id ',
          serviceCategoryId: ' category-id ',
          basePricePkr: 1200,
        ),
        isNull,
      );
    });

    test('rejects missing worker, missing category, and invalid base price',
        () {
      expect(
        workerServiceValidationError(
          workerId: ' ',
          serviceCategoryId: 'category-id',
          basePricePkr: 1200,
        ),
        WorkerServiceValidationError.missingWorker,
      );
      expect(
        workerServiceValidationError(
          workerId: 'worker-id',
          serviceCategoryId: ' ',
          basePricePkr: 1200,
        ),
        WorkerServiceValidationError.missingServiceCategory,
      );
      expect(
        workerServiceValidationError(
          workerId: 'worker-id',
          serviceCategoryId: 'category-id',
          basePricePkr: 0,
        ),
        WorkerServiceValidationError.invalidBasePrice,
      );
      expect(
        workerServiceValidationError(
          workerId: 'worker-id',
          serviceCategoryId: 'category-id',
          basePricePkr: -50,
        ),
        WorkerServiceValidationError.invalidBasePrice,
      );
    });

    test('upsertWorkerService blocks invalid prices before Supabase path', () {
      expect(
        () => ProfileRepository().upsertWorkerService(
          workerId: 'worker-id',
          serviceCategoryId: 'category-id',
          basePricePkr: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('workerDocumentExtensionError', () {
    test('allows jpg, jpeg, png, and pdf extensions after normalization', () {
      expect(workerDocumentExtensionError('jpg'), isNull);
      expect(workerDocumentExtensionError('.JPEG'), isNull);
      expect(workerDocumentExtensionError(' png '), isNull);
      expect(workerDocumentExtensionError('PDF'), isNull);
      expect(normalizedWorkerDocumentExtension('.JPEG'), 'jpeg');
    });

    test('rejects missing and unsupported document extensions', () {
      expect(
        workerDocumentExtensionError(null),
        WorkerDocumentExtensionError.unsupported,
      );
      expect(
        workerDocumentExtensionError(''),
        WorkerDocumentExtensionError.unsupported,
      );
      expect(
        workerDocumentExtensionError('docx'),
        WorkerDocumentExtensionError.unsupported,
      );
      expect(
        workerDocumentExtensionError('exe'),
        WorkerDocumentExtensionError.unsupported,
      );
    });
  });
}
