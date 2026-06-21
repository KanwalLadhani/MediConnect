import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/app/app_router.dart';

void main() {
  group('routeGuardRedirectForState', () {
    test('does nothing when Supabase is not configured', () {
      expect(
        routeGuardRedirectForState(
          path: '/orders/active',
          isSupabaseConfigured: false,
          isSignedIn: false,
        ),
        isNull,
      );
    });

    test('allows public routes for logged-out users', () {
      for (final path in ['/', '/login', '/role', '/register/patient']) {
        expect(
          routeGuardRedirectForState(
            path: path,
            isSupabaseConfigured: true,
            isSignedIn: false,
          ),
          isNull,
        );
      }
    });

    test('redirects logged-out protected routes to login', () {
      for (final path in [
        '/dashboard/patient',
        '/dashboard/worker',
        '/orders/active',
        '/orders/demo/chat',
        '/services',
        '/worker/requests',
        '/profile',
      ]) {
        expect(
          routeGuardRedirectForState(
            path: path,
            isSupabaseConfigured: true,
            isSignedIn: false,
          ),
          '/login',
        );
      }
    });

    test('sends signed-in users away from auth routes to resolved home', () {
      expect(
        routeGuardRedirectForState(
          path: '/login',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/dashboard/patient',
        ),
        '/dashboard/patient',
      );
    });

    test('keeps incomplete onboarding users on their onboarding route', () {
      expect(
        routeGuardRedirectForState(
          path: '/services',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/onboarding/patient',
        ),
        '/onboarding/patient',
      );

      expect(
        routeGuardRedirectForState(
          path: '/dashboard/worker',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/onboarding/worker',
        ),
        '/onboarding/worker',
      );
    });

    test('allows rejected or pending workers to resubmit documents only', () {
      expect(
        routeGuardRedirectForState(
          path: '/dashboard/worker',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/verification-pending',
        ),
        '/verification-pending',
      );

      expect(
        routeGuardRedirectForState(
          path: '/onboarding/worker',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/verification-pending',
        ),
        isNull,
      );
    });

    test('blocks patients from worker routes and workers from patient routes',
        () {
      expect(
        routeGuardRedirectForState(
          path: '/worker/requests',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/dashboard/patient',
        ),
        '/dashboard/patient',
      );

      expect(
        routeGuardRedirectForState(
          path: '/services/request',
          isSupabaseConfigured: true,
          isSignedIn: true,
          homePath: '/dashboard/worker',
        ),
        '/dashboard/worker',
      );
    });
  });
}
