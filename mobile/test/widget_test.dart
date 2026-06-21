import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/app/app.dart';
import 'package:mediconnect/app/app_locale_controller.dart';
import 'package:mediconnect/app/app_router.dart';
import 'package:mediconnect/features/dashboard/worker_dashboard_screen.dart';
import 'package:mediconnect/features/onboarding/patient_onboarding_screen.dart';
import 'package:mediconnect/features/services/patient_services_screen.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

void main() {
  testWidgets('landing screen shows patient and worker entry actions',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MediConnectApp());
    await tester.pump();

    expect(find.text('MediConnect'), findsOneWidget);
    expect(find.text('Healthcare help at your doorstep.'), findsOneWidget);
    expect(find.text('Continue as Patient'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);

    await tester.drag(find.byType(Scrollable), const Offset(0, -260));
    await tester.pump();

    expect(find.text('Join as Health Worker'), findsOneWidget);
  });

  testWidgets('direct order chat route loads without in-memory route extra',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    appRouter.go('/orders/demo-order-1/chat');
    await tester.pumpWidget(const MediConnectApp());
    await tester.pumpAndSettle();

    expect(find.text('Injection'), findsOneWidget);
    expect(
      find.text('Please call when you are near the house.'),
      findsOneWidget,
    );
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('Urdu role selection renders right-to-left', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    appLocaleController.value = const Locale('ur');
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => appLocaleController.value = null);

    appRouter.go('/role');
    await tester.pumpWidget(const MediConnectApp());
    await tester.pumpAndSettle();

    const title = 'آپ MediConnect کیسے استعمال کریں گے؟';
    expect(find.text(title), findsOneWidget);
    expect(find.text('مریض'), findsOneWidget);
    expect(find.text('ہیلتھ ورکر'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(title))),
      TextDirection.rtl,
    );
  });

  testWidgets('Urdu patient onboarding renders localized required fields',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ur'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PatientOnboardingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    const title = 'مریض کی تفصیلات';
    expect(find.text(title), findsOneWidget);
    expect(find.text('پتہ'), findsOneWidget);
    expect(find.text('شہر'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(title))),
      TextDirection.rtl,
    );
  });

  testWidgets('core mobile polish screens tolerate text scaling and RTL',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _localizedHarness(
        locale: const Locale('en'),
        textScaler: const TextScaler.linear(1.45),
        child: const WorkerDashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Worker dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _localizedHarness(
        locale: const Locale('ur'),
        textScaler: const TextScaler.linear(1.25),
        child: const PatientServicesScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.byType(PatientServicesScreen))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _localizedHarness({
  required Locale locale,
  required Widget child,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: textScaler),
      child: child,
    ),
  );
}
