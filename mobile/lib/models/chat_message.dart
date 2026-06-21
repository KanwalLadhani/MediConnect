class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderUserId,
    required this.messageType,
    required this.createdAt,
    this.body,
    this.filePath,
    this.fileUrl,
  });

  final String id;
  final String senderUserId;
  final String messageType;
  final DateTime createdAt;
  final String? body;
  final String? filePath;
  final String? fileUrl;

  bool get isImage => messageType == 'image';
}
