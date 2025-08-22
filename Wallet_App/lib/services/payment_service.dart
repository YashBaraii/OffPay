import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();

  PaymentService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user's balance
  Future<double> getUserBalance() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('user_profiles')
          .select('balance')
          .eq('id', userId)
          .single();

      return (response['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (error) {
      throw Exception('Failed to get user balance: $error');
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  // Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions(
      {int limit = 10}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('transactions')
          .select('*')
          .or('sender_id.eq.$userId,recipient_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get transactions: $error');
    }
  }

  // Create a new transaction
  Future<Map<String, dynamic>> createTransaction({
    required String recipientName,
    String? recipientEmail,
    required double amount,
    String? description,
    String? recipientId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final transactionData = {
        'sender_id': userId,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'recipient_email': recipientEmail,
        'amount': amount,
        'description': description,
        'transaction_type': 'sent',
        'status': 'pending',
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create transaction: $error');
    }
  }

  // Update transaction status
  Future<Map<String, dynamic>> updateTransactionStatus(
    String transactionId,
    String status,
  ) async {
    try {
      final response = await _client
          .from('transactions')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', transactionId)
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to update transaction status: $error');
    }
  }

  // Get user contacts
  Future<List<Map<String, dynamic>>> getUserContacts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('contacts')
          .select('*')
          .eq('user_id', userId)
          .order('contact_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to get contacts: $error');
    }
  }

  // Add new contact
  Future<Map<String, dynamic>> addContact({
    required String contactName,
    String? contactEmail,
    String? contactPhone,
    bool isFavorite = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final contactData = {
        'user_id': userId,
        'contact_name': contactName,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'is_favorite': isFavorite,
      };

      final response =
          await _client.from('contacts').insert(contactData).select().single();

      return response;
    } catch (error) {
      throw Exception('Failed to add contact: $error');
    }
  }

  // Format transaction for UI display
  Map<String, dynamic> formatTransactionForUI(
    Map<String, dynamic> transaction,
    String currentUserId,
  ) {
    final isReceived = transaction['recipient_id'] == currentUserId;
    final createdAt = DateTime.parse(transaction['created_at']);

    return {
      'id': transaction['id'],
      'type': isReceived ? 'received' : 'sent',
      'recipient': isReceived
          ? 'From ${transaction['sender_id'] ?? 'Unknown'}'
          : transaction['recipient_name'] ?? 'Unknown',
      'amount': (transaction['amount'] as num).toDouble(),
      'status': transaction['status'],
      'timestamp': _formatTimestamp(createdAt),
      'description': transaction['description'] ?? 'No description',
      'reference_number': transaction['reference_number'],
    };
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today
      final hour = timestamp.hour > 12
          ? timestamp.hour - 12
          : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
      return 'Today, ${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $amPm';
    } else if (difference.inDays == 1) {
      // Yesterday
      final hour = timestamp.hour > 12
          ? timestamp.hour - 12
          : (timestamp.hour == 0 ? 12 : timestamp.hour);
      final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
      return 'Yesterday, ${hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')} $amPm';
    } else {
      // Older
      return '${difference.inDays} days ago, ${timestamp.hour.toString()}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  // Subscribe to real-time transaction changes
  RealtimeChannel subscribeToTransactions(
      Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }
}
