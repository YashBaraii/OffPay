class Transaction {
  final String id;
  final String transactionNumber;
  final String? senderId;
  final String? receiverId;
  final String? senderWalletId;
  final String? receiverWalletId;
  final double amount;
  final String transactionType;
  final String transactionStatus;
  final String? note;
  final String? referenceCode;
  final String? failureReason;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for UI display (will be populated from joins)
  final String? senderName;
  final String? receiverName;

  Transaction({
    required this.id,
    required this.transactionNumber,
    this.senderId,
    this.receiverId,
    this.senderWalletId,
    this.receiverWalletId,
    required this.amount,
    required this.transactionType,
    required this.transactionStatus,
    this.note,
    this.referenceCode,
    this.failureReason,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.senderName,
    this.receiverName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      transactionNumber: json['transaction_number'] as String,
      senderId: json['sender_id'] as String?,
      receiverId: json['receiver_id'] as String?,
      senderWalletId: json['sender_wallet_id'] as String?,
      receiverWalletId: json['receiver_wallet_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      transactionType: json['transaction_type'] as String,
      transactionStatus: json['transaction_status'] as String,
      note: json['note'] as String?,
      referenceCode: json['reference_code'] as String?,
      failureReason: json['failure_reason'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      senderName: json['sender_name'] as String?,
      receiverName: json['receiver_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_number': transactionNumber,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_wallet_id': senderWalletId,
      'receiver_wallet_id': receiverWalletId,
      'amount': amount,
      'transaction_type': transactionType,
      'transaction_status': transactionStatus,
      'note': note,
      'reference_code': referenceCode,
      'failure_reason': failureReason,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for UI
  bool get isReceived => transactionType == 'received';
  bool get isSent => transactionType == 'sent';
  bool get isCompleted => transactionStatus == 'completed';
  bool get isPending => transactionStatus == 'pending';
  bool get isFailed => transactionStatus == 'failed';

  String get displayAmount => '\$${amount.toStringAsFixed(2)}';
  String get formattedAmount => '${isReceived ? '+' : '-'}$displayAmount';

  String get otherPartyName {
    if (isReceived) return senderName ?? 'Unknown Sender';
    return receiverName ?? 'Unknown Receiver';
  }

  String get timestamp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
