enum TicketPriority {
  critical(label: 'بحرانی', color: 0xFFDC2626),
  high(label: 'بالا', color: 0xFFEA580C),
  medium(label: 'متوسط', color: 0xFFD97706),
  low(label: 'عادی', color: 0xFF2563EB);

  final String label;
  final int color;
  const TicketPriority({required this.label, required this.color});
}

enum TicketStatus {
  open(label: 'باز / در انتظار پاسخ', color: 0xFFD97706),
  inProgress(label: 'در حال بررسی فنی', color: 0xFF2563EB),
  resolved(label: 'حل شده و بسته', color: 0xFF16A34A);

  final String label;
  final int color;
  const TicketStatus({required this.label, required this.color});
}

class TicketChatMessage {
  final String sender;
  final bool isFromAdmin;
  final String message;
  final DateTime timestamp;

  const TicketChatMessage({
    required this.sender,
    required this.isFromAdmin,
    required this.message,
    required this.timestamp,
  });
}

class SupportTicketItem {
  final String ticketId;
  final String userId;
  final String userName;
  final String userEmail;
  final int userCoinBalance;
  final String subject;
  final String category;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final List<TicketChatMessage> messages;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String ipAddress;
  final String? relatedTxId;
  final String? recentAiErrorLog;

  const SupportTicketItem({
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userCoinBalance,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.messages,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.ipAddress,
    this.relatedTxId,
    this.recentAiErrorLog,
  });

  SupportTicketItem copyWith({
    String? ticketId,
    String? userId,
    String? userName,
    String? userEmail,
    int? userCoinBalance,
    String? subject,
    String? category,
    TicketPriority? priority,
    TicketStatus? status,
    DateTime? createdAt,
    List<TicketChatMessage>? messages,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    String? ipAddress,
    String? relatedTxId,
    String? recentAiErrorLog,
  }) {
    return SupportTicketItem(
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userCoinBalance: userCoinBalance ?? this.userCoinBalance,
      subject: subject ?? this.subject,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      messages: messages ?? this.messages,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      ipAddress: ipAddress ?? this.ipAddress,
      relatedTxId: relatedTxId ?? this.relatedTxId,
      recentAiErrorLog: recentAiErrorLog ?? this.recentAiErrorLog,
    );
  }
}
