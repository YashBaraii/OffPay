class WalletAccount {
  final String id;
  final String userId;
  final String accountNumber;
  final double balance;
  final String walletType;
  final bool isActive;
  final double dailyLimit;
  final double monthlyLimit;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletAccount({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.balance,
    required this.walletType,
    required this.isActive,
    required this.dailyLimit,
    required this.monthlyLimit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    return WalletAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountNumber: json['account_number'] as String,
      balance: (json['balance'] as num).toDouble(),
      walletType: json['wallet_type'] as String,
      isActive: json['is_active'] as bool,
      dailyLimit: (json['daily_limit'] as num).toDouble(),
      monthlyLimit: (json['monthly_limit'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_number': accountNumber,
      'balance': balance,
      'wallet_type': walletType,
      'is_active': isActive,
      'daily_limit': dailyLimit,
      'monthly_limit': monthlyLimit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
