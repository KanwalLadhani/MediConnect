import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../common/widgets/app_state_widgets.dart';
import '../../common/widgets/app_text_field.dart';
import '../../models/user_role.dart';
import '../../models/worker_wallet.dart';
import '../../services/wallet_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class WorkerWalletScreen extends StatefulWidget {
  const WorkerWalletScreen({super.key});

  @override
  State<WorkerWalletScreen> createState() => _WorkerWalletScreenState();
}

class _WorkerWalletScreenState extends State<WorkerWalletScreen> {
  final _repository = WalletRepository();
  late Future<WorkerWallet> _walletFuture;

  @override
  void initState() {
    super.initState();
    _walletFuture = _repository.fetchWallet();
  }

  void _refresh() {
    setState(() {
      _walletFuture = _repository.fetchWallet();
    });
  }

  Future<void> _openTopUpSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _TopUpSheet(),
    );

    if (submitted == true) {
      _refresh();
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.topUpSubmitted)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wallet)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.healthWorker,
        currentItem: RoleNavItem.wallet,
      ),
      body: FutureBuilder<WorkerWallet>(
        future: _walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppLoadingState(message: l10n.wallet);
          }

          if (snapshot.hasError) {
            return AppErrorState(
              message: snapshot.error.toString(),
              retryLabel: l10n.retry,
              onRetry: _refresh,
            );
          }

          final wallet = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.availableBalance),
                        const SizedBox(height: 8),
                        Text(
                          'PKR ${wallet.balancePkr}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.statusLabel(_labelize(wallet.status))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openTopUpSheet,
                  icon: const Icon(Icons.add_card_outlined),
                  label: Text(
                    l10n.requestWalletTopUpButton,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.transactions,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                if (wallet.transactions.isEmpty)
                  AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.transactions,
                    subtitle: l10n.noWalletTransactions,
                    compact: true,
                  )
                else
                  ...wallet.transactions.map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          isThreeLine: transaction.reference != null,
                          leading: Icon(
                            transaction.direction == 'credit'
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                          ),
                          title: Text(_labelize(transaction.type)),
                          subtitle: Text(
                            '${_labelize(transaction.status)}'
                            '${transaction.reference == null ? '' : ' - ${transaction.reference}'}',
                          ),
                          trailing: Text(
                            '${transaction.direction == 'credit' ? '+' : '-'}PKR ${transaction.amountPkr}',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _repository = WalletRepository();
  final _imagePicker = ImagePicker();

  String _method = 'JazzCash';
  Uint8List? _screenshotBytes;
  String? _screenshotExtension;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
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
      _screenshotBytes = bytes;
      _screenshotExtension = image.name.split('.').last;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _repository.requestTopUp(
        amountPkr: parseWalletTopUpAmount(_amountController.text)!,
        method: _method,
        reference: _referenceController.text.trim(),
        screenshotBytes: _screenshotBytes,
        screenshotExtension: _screenshotExtension,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.requestWalletTopUp,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'JazzCash', label: Text('JazzCash')),
                    ButtonSegment(value: 'EasyPaisa', label: Text('EasyPaisa')),
                  ],
                  selected: {_method},
                  onSelectionChanged: (value) {
                    setState(() => _method = value.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _amountController,
                label: l10n.amountPkr,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (walletTopUpAmountError(value) != null) {
                    return l10n.enterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _referenceController,
                label: l10n.transactionReference,
                validator: (value) {
                  if (walletTopUpReferenceError(value) != null) {
                    return l10n.enterTransactionReference;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(
                    _screenshotBytes == null
                        ? Icons.upload_file_outlined
                        : Icons.check_circle_outline,
                  ),
                  title: Text(
                    _screenshotBytes == null
                        ? l10n.attachScreenshot
                        : l10n.screenshotAttached,
                  ),
                  subtitle: Text(l10n.optionalRecommended),
                  onTap: _pickScreenshot,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label:
                    Text(l10n.submitTopUpRequest, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _labelize(String value) {
  return value
      .split('_')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
