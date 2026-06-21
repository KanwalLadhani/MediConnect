import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/models/user_role.dart';
import 'package:mediconnect/services/auth_repository.dart';

void main() {
  group('authRegistrationValidationError', () {
    test('allows valid registration fields after trimming', () {
      expect(
        authRegistrationValidationError(
          email: ' demo.patient@mediconnect.test ',
          password: 'secret123',
          fullName: ' Demo Patient ',
          phone: ' +92 300 0000000 ',
        ),
        isNull,
      );
    });

    test('rejects invalid registration fields', () {
      AuthValidationError? errorFor({
        String email = 'demo.patient@mediconnect.test',
        String password = 'secret123',
        String fullName = 'Demo Patient',
        String phone = '+92 300 0000000',
      }) {
        return authRegistrationValidationError(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        );
      }

      expect(errorFor(email: ' '), AuthValidationError.missingEmail);
      expect(errorFor(email: 'not-an-email'), AuthValidationError.invalidEmail);
      expect(errorFor(password: '12345'), AuthValidationError.passwordTooShort);
      expect(errorFor(fullName: ' '), AuthValidationError.missingFullName);
      expect(errorFor(phone: ' '), AuthValidationError.missingPhone);
    });

    test('signUpWithEmail blocks invalid fields before Supabase path', () {
      expect(
        () => AuthRepository().signUpWithEmail(
          email: 'not-an-email',
          password: 'secret123',
          fullName: 'Demo Patient',
          phone: '+92 300 0000000',
          role: UserRole.patient,
        ),
        throwsArgumentError,
      );
    });
  });

  group('authLoginValidationError', () {
    test('allows valid login fields after trimming', () {
      expect(
        authLoginValidationError(
          email: ' demo.patient@mediconnect.test ',
          password: 'secret123',
        ),
        isNull,
      );
    });

    test('rejects invalid login fields', () {
      expect(
        authLoginValidationError(email: '', password: 'secret123'),
        AuthValidationError.missingEmail,
      );
      expect(
        authLoginValidationError(email: 'demo', password: 'secret123'),
        AuthValidationError.invalidEmail,
      );
      expect(
        authLoginValidationError(
          email: 'demo.patient@mediconnect.test',
          password: '12345',
        ),
        AuthValidationError.passwordTooShort,
      );
    });

    test('signInWithEmail blocks invalid fields before Supabase path', () {
      expect(
        () => AuthRepository().signInWithEmail(
          email: 'demo.patient@mediconnect.test',
          password: '12345',
        ),
        throwsArgumentError,
      );
    });
  });
}
