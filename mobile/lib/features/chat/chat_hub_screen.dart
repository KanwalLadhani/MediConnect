import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mediconnect/l10n/app_localizations.dart';

import '../../models/service_order.dart';
import '../../models/user_role.dart';
import '../../services/order_repository.dart';
import '../navigation/role_bottom_navigation.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  final _repository = OrderRepository();
  late Future<List<ServiceOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _repository.fetchActiveOrders();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _repository.fetchActiveOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chats)),
      bottomNavigationBar: const RoleBottomNavigation(
        role: UserRole.patient,
        currentItem: RoleNavItem.chat,
      ),
      body: FutureBuilder<List<ServiceOrder>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snapshot.error.toString()),
              ),
            );
          }

          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const _EmptyChats();
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(order.categoryName),
                      subtitle: Text(
                        '${order.workerName} - ${_labelize(order.status)}',
                      ),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.push(
                        '/orders/${order.id}/chat',
                        extra: order,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noActiveChats,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.chatHubEmptyMessage,
              textAlign: TextAlign.center,
            ),
          ],
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
