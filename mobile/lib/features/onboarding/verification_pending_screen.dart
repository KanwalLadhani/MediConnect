import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/page_shell.dart';
import '../../services/auth_repository.dart';
import '../../services/profile_repository.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() =>
      _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  final _profileRepository = ProfileRepository();
  final _authRepository = AuthRepository();
  late Future<Map<String, dynamic>?> _verificationFuture;

  @override
  void initState() {
    super.initState();
    _verificationFuture = _profileRepository.fetchCurrentWorkerVerification();
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) {
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _verificationFuture,
      builder: (context, snapshot) {
        final verification = snapshot.data;
        final status = verification?['verification_status'] as String?;
        final rejectionReason = verification?['rejection_reason'] as String?;
        final isRejected = status == 'rejected';

        return PageShell(
          title:
              isRejected ? l10n.verificationRejected : l10n.verificationPending,
          subtitle: isRejected
              ? l10n.verificationRejectedSubtitle
              : l10n.verificationPendingSubtitle,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isRejected
                          ? Icons.error_outline
                          : Icons.hourglass_top_outlined,
                      color: isRejected
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      size: 36,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRejected ? l10n.adminNote : l10n.expectedReviewTime,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRejected
                          ? rejectionReason ?? l10n.workerCorrectionFallback
                          : l10n.workerReviewTimeCopy,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/onboarding/worker'),
              icon: const Icon(Icons.edit_document),
              label: Text(
                isRejected ? l10n.resubmitDetails : l10n.reviewSubmittedDetails,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: Text(l10n.signOut),
            ),
          ],
        );
      },
    );
  }
}
