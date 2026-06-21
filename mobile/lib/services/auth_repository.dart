import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import 'profile_repository.dart';
import 'supabase_status.dart';

class AuthRepository {
  AuthRepository({
    ProfileRepository? profileRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    final validationError = authRegistrationValidationError(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
    if (validationError != null) {
      throw ArgumentError(authValidationMessage(validationError));
    }

    final response = await SupabaseStatus.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'role': role.value,
      },
    );

    final user = response.user;
    if (user != null) {
      await _profileRepository.upsertProfile(
        userId: user.id,
        role: role,
        fullName: fullName.trim(),
        phone: phone.trim(),
        email: email.trim(),
      );
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    final validationError = authLoginValidationError(
      email: email,
      password: password,
    );
    if (validationError != null) {
      throw ArgumentError(authValidationMessage(validationError));
    }

    return SupabaseStatus.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() {
    return SupabaseStatus.client.auth.signOut();
  }
}

AuthValidationError? authRegistrationValidationError({
  required String email,
  required String password,
  required String fullName,
  required String phone,
}) {
  final emailError = authEmailError(email);
  if (emailError != null) {
    return emailError;
  }
  final passwordError = authPasswordError(password);
  if (passwordError != null) {
    return passwordError;
  }
  if (fullName.trim().isEmpty) {
    return AuthValidationError.missingFullName;
  }
  if (phone.trim().isEmpty) {
    return AuthValidationError.missingPhone;
  }

  return null;
}

AuthValidationError? authLoginValidationError({
  required String email,
  required String password,
}) {
  return authEmailError(email) ?? authPasswordError(password);
}

AuthValidationError? authEmailError(String? email) {
  final normalized = email?.trim() ?? '';
  if (normalized.isEmpty) {
    return AuthValidationError.missingEmail;
  }
  if (!_emailPattern.hasMatch(normalized)) {
    return AuthValidationError.invalidEmail;
  }

  return null;
}

AuthValidationError? authPasswordError(String? password) {
  if ((password ?? '').length < 6) {
    return AuthValidationError.passwordTooShort;
  }

  return null;
}

String authValidationMessage(AuthValidationError error) {
  return switch (error) {
    AuthValidationError.missingEmail => 'Enter email.',
    AuthValidationError.invalidEmail => 'Enter a valid email.',
    AuthValidationError.passwordTooShort => 'Use at least 6 characters.',
    AuthValidationError.missingFullName => 'Enter full name.',
    AuthValidationError.missingPhone => 'Enter phone number.',
  };
}

enum AuthValidationError {
  missingEmail,
  invalidEmail,
  passwordTooShort,
  missingFullName,
  missingPhone,
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
