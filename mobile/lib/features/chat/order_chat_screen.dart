import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediconnect/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/chat_message.dart';
import '../../models/service_order.dart';
import '../../services/order_repository.dart';
import '../../services/supabase_status.dart';

class OrderChatLoaderScreen extends StatefulWidget {
  const OrderChatLoaderScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  State<OrderChatLoaderScreen> createState() => _OrderChatLoaderScreenState();
}

class _OrderChatLoaderScreenState extends State<OrderChatLoaderScreen> {
  final _repository = OrderRepository();
  late Future<ServiceOrder?> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _repository.fetchOrderById(widget.orderId);
  }

  void _retry() {
    setState(() {
      _orderFuture = _repository.fetchOrderById(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceOrder?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _OrderChatLoadError(
            message: snapshot.error.toString(),
            onRetry: _retry,
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return _OrderChatLoadError(
            message: AppLocalizations.of(context)!.orderChatUnavailable,
            onRetry: _retry,
          );
        }

        return OrderChatScreen(order: order);
      },
    );
  }
}

class OrderChatScreen extends StatefulWidget {
  const OrderChatScreen({
    required this.order,
    super.key,
  });

  final ServiceOrder order;

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _repository = OrderRepository();
  final _messageController = TextEditingController();
  final _imagePicker = ImagePicker();

  late Future<String> _chatFuture;
  String? _chatId;
  RealtimeChannel? _messagesChannel;
  List<ChatMessage> _messages = const [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatFuture = _loadChat();
  }

  @override
  void dispose() {
    final channel = _messagesChannel;
    if (channel != null && SupabaseStatus.isConfigured) {
      SupabaseStatus.client.removeChannel(channel);
    }
    _messageController.dispose();
    super.dispose();
  }

  Future<String> _loadChat() async {
    final chatId = await _repository.ensureChat(widget.order.id);
    final messages = await _repository.fetchMessages(chatId);
    if (mounted) {
      setState(() {
        _chatId = chatId;
        _messages = messages;
      });
      _subscribeToMessages(chatId);
    }
    return chatId;
  }

  Future<void> _refresh() async {
    final chatId = _chatId ?? await _chatFuture;
    final messages = await _repository.fetchMessages(chatId);
    if (mounted) {
      setState(() => _messages = messages);
    }
  }

  void _subscribeToMessages(String chatId) {
    if (!SupabaseStatus.isConfigured || _messagesChannel != null) {
      return;
    }

    _messagesChannel = SupabaseStatus.client
        .channel('chat_messages_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (_) => _refresh(),
        )
        .subscribe();
  }

  Future<void> _sendText() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final chatId = _chatId ?? await _chatFuture;
      await _repository.sendTextMessage(chatId: chatId, body: body);
      _messageController.clear();
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );

    if (image == null) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final chatId = _chatId ?? await _chatFuture;
      await _repository.sendImageMessage(
        chatId: chatId,
        bytes: await image.readAsBytes(),
        extension: image.name.split('.').last,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _repository.currentUserId();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.categoryName),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _chatFuture,
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

          return Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _MessageBubble(
                            message: message,
                            isMine: message.senderUserId == currentUserId,
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.attachImage,
                        onPressed: _isSending ? null : _sendImage,
                        icon: const Icon(Icons.image_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: l10n.message,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: l10n.send,
                        onPressed: _isSending ? null : _sendText,
                        icon: _isSending
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderChatLoadError extends StatelessWidget {
  const _OrderChatLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderChat)),
      body: Center(
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
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primary : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: message.isImage
            ? _ChatImage(message: message, isMine: isMine)
            : Text(
                message.body ?? '',
                style: TextStyle(
                  color: isMine ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
      ),
    );
  }
}

class _ChatImage extends StatelessWidget {
  const _ChatImage({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isMine ? colorScheme.onPrimary : colorScheme.onSurface;

    if (message.fileUrl == null) {
      return Text(
        l10n.imageAttachmentWithName(message.filePath ?? l10n.uploaded),
        style: TextStyle(color: textColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) {
                return child;
              }
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                height: 120,
                child: Center(
                  child: Text(
                    l10n.imageCouldNotBeLoaded,
                    style: TextStyle(color: textColor),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.imageAttachment,
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

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
              l10n.noMessagesYet,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.chatGuidance,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
