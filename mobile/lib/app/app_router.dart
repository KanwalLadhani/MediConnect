import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/role_selection_screen.dart';
import '../features/chat/chat_hub_screen.dart';
import '../features/chat/order_chat_screen.dart';
import '../features/dashboard/patient_dashboard_screen.dart';
import '../features/dashboard/worker_dashboard_screen.dart';
import '../features/landing/landing_screen.dart';
import '../features/navigation/role_bottom_navigation.dart';
import '../features/onboarding/patient_onboarding_screen.dart';
import '../features/onboarding/verification_pending_screen.dart';
import '../features/onboarding/worker_onboarding_screen.dart';
import '../features/orders/active_orders_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/services/available_workers_screen.dart';
import '../features/services/patient_services_screen.dart';
import '../features/services/service_request_screen.dart';
import '../features/wallet/worker_wallet_screen.dart';
import '../features/worker/incoming_requests_screen.dart';
import '../models/service_category.dart';
import '../models/service_order.dart';
import '../models/service_request_result.dart';
import '../models/user_role.dart';
import '../services/profile_repository.dart';
import '../services/supabase_status.dart';

final _profileRepository = ProfileRepository();

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: _guardRedirect,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register/:role',
      builder: (context, state) {
        final role = state.pathParameters['role'] ?? 'patient';
        return RegisterScreen(role: role);
      },
    ),
    GoRoute(
      path: '/onboarding/patient',
      builder: (context, state) => const PatientOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/worker',
      builder: (context, state) => const WorkerOnboardingScreen(),
    ),
    GoRoute(
      path: '/verification-pending',
      builder: (context, state) => const VerificationPendingScreen(),
    ),
    GoRoute(
      path: '/dashboard/patient',
      builder: (context, state) => const PatientDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/worker',
      builder: (context, state) => const WorkerDashboardScreen(),
    ),
    GoRoute(
      path: '/worker/requests',
      builder: (context, state) => const IncomingRequestsScreen(),
    ),
    GoRoute(
      path: '/worker/wallet',
      builder: (context, state) => const WorkerWalletScreen(),
    ),
    GoRoute(
      path: '/worker/active',
      builder: (context, state) => const ActiveOrdersScreen(
        navigationRole: UserRole.healthWorker,
        navigationItem: RoleNavItem.active,
      ),
    ),
    GoRoute(
      path: '/orders/active',
      builder: (context, state) => const ActiveOrdersScreen(
        navigationRole: UserRole.patient,
        navigationItem: RoleNavItem.orders,
      ),
    ),
    GoRoute(
      path: '/orders/history',
      builder: (context, state) => const OrderHistoryScreen(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const PatientServicesScreen(),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ChatHubScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/orders/:id/chat',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ServiceOrder) {
          return OrderChatScreen(order: extra);
        }

        return OrderChatLoaderScreen(
          orderId: state.pathParameters['id'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/services/request',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ServiceCategory) {
          return ServiceRequestScreen(category: extra);
        }

        return const PatientServicesScreen();
      },
    ),
    GoRoute(
      path: '/services/workers',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is ServiceRequestResult) {
          return AvailableWorkersScreen(request: extra);
        }

        return const PatientServicesScreen();
      },
    ),
  ],
);

Future<String?> _guardRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final path = state.uri.path;

  if (!SupabaseStatus.isConfigured) {
    return routeGuardRedirectForState(
      path: path,
      isSupabaseConfigured: false,
      isSignedIn: false,
    );
  }

  final user = SupabaseStatus.client.auth.currentUser;
  if (user == null) {
    return routeGuardRedirectForState(
      path: path,
      isSupabaseConfigured: true,
      isSignedIn: false,
    );
  }

  final homePath = await _profileRepository.resolveCurrentHomePath();

  return routeGuardRedirectForState(
    path: path,
    isSupabaseConfigured: true,
    isSignedIn: true,
    homePath: homePath,
  );
}

@visibleForTesting
String? routeGuardRedirectForState({
  required String path,
  required bool isSupabaseConfigured,
  required bool isSignedIn,
  String? homePath,
}) {
  if (!isSupabaseConfigured) {
    return null;
  }

  final isPublicPath = path == '/' ||
      path == '/login' ||
      path == '/role' ||
      path.startsWith('/register/');

  if (!isSignedIn) {
    return isPublicPath ? null : '/login';
  }

  final resolvedHomePath = homePath;
  if (resolvedHomePath == null || resolvedHomePath.isEmpty) {
    return null;
  }

  final isAuthPath = path == '/' ||
      path == '/login' ||
      path == '/role' ||
      path.startsWith('/register/');

  if (isAuthPath) {
    return resolvedHomePath;
  }

  if (resolvedHomePath == '/onboarding/patient' && path != resolvedHomePath) {
    return resolvedHomePath;
  }

  if (resolvedHomePath == '/onboarding/worker' && path != resolvedHomePath) {
    return resolvedHomePath;
  }

  if (resolvedHomePath == '/verification-pending' &&
      path != resolvedHomePath &&
      path != '/onboarding/worker') {
    return resolvedHomePath;
  }

  if (resolvedHomePath == '/dashboard/patient' &&
      (path == '/dashboard/worker' || path.startsWith('/worker/'))) {
    return resolvedHomePath;
  }

  if (resolvedHomePath == '/dashboard/worker' &&
      (path == '/dashboard/patient' ||
          path == '/services' ||
          path.startsWith('/services/'))) {
    return resolvedHomePath;
  }

  return null;
}
