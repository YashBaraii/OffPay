import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/wallet_account.dart';
import './supabase_service.dart';

class TransactionService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Send money to another user
  Future<Transaction> sendMoney({
    required String receiverIdentifier, // Account number or QR code
    required double amount,
    String? note,
    String? senderWalletId,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Find receiver by identifier
      UserProfile? receiver;
      WalletAccount? receiverWallet;

      // Try account number first
      final walletResponse = await _client
          .from('wallet_accounts')
          .select('*, user_profiles!inner(*)')
          .eq('account_number', receiverIdentifier)
          .eq('is_active', true)
          .maybeSingle();

      if (walletResponse != null) {
        receiverWallet = WalletAccount.fromJson(walletResponse);
        receiver = UserProfile.fromJson(walletResponse['user_profiles']);
      } else {
        // Try QR code
        final userResponse = await _client
            .from('user_profiles')
            .select('*, wallet_accounts!inner(*)')
            .eq('qr_code', receiverIdentifier)
            .eq('is_active', true)
            .maybeSingle();

        if (userResponse != null) {
          receiver = UserProfile.fromJson(userResponse);
          final wallets = (userResponse['wallet_accounts'] as List)
              .map((w) => WalletAccount.fromJson(w))
              .where((w) => w.isActive)
              .toList();
          receiverWallet = wallets.isNotEmpty ? wallets.first : null;
        }
      }

      if (receiver == null || receiverWallet == null) {
        throw Exception('Receiver not found');
      }

      // Get sender wallet
      WalletAccount? senderWallet;
      if (senderWalletId != null) {
        final senderWalletResponse = await _client
            .from('wallet_accounts')
            .select()
            .eq('id', senderWalletId)
            .eq('user_id', currentUserId)
            .single();
        senderWallet = WalletAccount.fromJson(senderWalletResponse);
      } else {
        final senderWallets = await _client
            .from('wallet_accounts')
            .select()
            .eq('user_id', currentUserId)
            .eq('is_active', true)
            .order('created_at')
            .limit(1);

        if (senderWallets.isNotEmpty) {
          senderWallet = WalletAccount.fromJson(senderWallets.first);
        }
      }

      if (senderWallet == null) {
        throw Exception('Sender wallet not found');
      }

      // Check sufficient balance
      if (senderWallet.balance < amount) {
        throw Exception('Insufficient balance');
      }

      // Create transaction
      final transactionData = {
        'sender_id': currentUserId,
        'receiver_id': receiver.id,
        'sender_wallet_id': senderWallet.id,
        'receiver_wallet_id': receiverWallet.id,
        'amount': amount,
        'transaction_type': 'sent',
        'transaction_status': 'pending',
        'note': note,
      };

      final response = await _client
          .from('transactions')
          .insert(transactionData)
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (error) {
      throw Exception('Send money failed: $error');
    }
  }

  // Complete transaction (usually triggered by database trigger)
  Future<Transaction> completeTransaction(String transactionId) async {
    try {
      final response = await _client
          .from('transactions')
          .update({
            'transaction_status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId)
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (error) {
      throw Exception('Complete transaction failed: $error');
    }
  }

  // Cancel pending transaction
  Future<Transaction> cancelTransaction(String transactionId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client
          .from('transactions')
          .update({
            'transaction_status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId)
          .eq('sender_id', currentUserId)
          .eq('transaction_status', 'pending')
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (error) {
      throw Exception('Cancel transaction failed: $error');
    }
  }

  // Get user transactions with pagination
  Future<List<Transaction>> getUserTransactions({
    int? limit = 20,
    int? offset = 0,
    String? status,
    String? type,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      var query = _client.from('transactions').select('''
            *,
            sender_profiles:sender_id(full_name),
            receiver_profiles:receiver_id(full_name)
          ''').or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

      if (status != null) {
        query = query.eq('transaction_status', status);
      }

      if (type != null) {
        if (type == 'sent') {
          query = query.eq('sender_id', currentUserId);
        } else if (type == 'received') {
          query = query.eq('receiver_id', currentUserId);
        }
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset!, offset + limit! - 1);

      return (response as List).map((txn) {
        final transaction = Transaction.fromJson(txn);
        return Transaction(
          id: transaction.id,
          transactionNumber: transaction.transactionNumber,
          senderId: transaction.senderId,
          receiverId: transaction.receiverId,
          senderWalletId: transaction.senderWalletId,
          receiverWalletId: transaction.receiverWalletId,
          amount: transaction.amount,
          transactionType: transaction.transactionType,
          transactionStatus: transaction.transactionStatus,
          note: transaction.note,
          referenceCode: transaction.referenceCode,
          failureReason: transaction.failureReason,
          completedAt: transaction.completedAt,
          createdAt: transaction.createdAt,
          updatedAt: transaction.updatedAt,
          senderName: txn['sender_profiles']?['full_name'],
          receiverName: txn['receiver_profiles']?['full_name'],
        );
      }).toList();
    } catch (error) {
      throw Exception('Failed to get transactions: $error');
    }
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String transactionId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client
          .from('transactions')
          .select('''
            *,
            sender_profiles:sender_id(full_name),
            receiver_profiles:receiver_id(full_name)
          ''')
          .eq('id', transactionId)
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .maybeSingle();

      if (response == null) return null;

      final transaction = Transaction.fromJson(response);
      return Transaction(
        id: transaction.id,
        transactionNumber: transaction.transactionNumber,
        senderId: transaction.senderId,
        receiverId: transaction.receiverId,
        senderWalletId: transaction.senderWalletId,
        receiverWalletId: transaction.receiverWalletId,
        amount: transaction.amount,
        transactionType: transaction.transactionType,
        transactionStatus: transaction.transactionStatus,
        note: transaction.note,
        referenceCode: transaction.referenceCode,
        failureReason: transaction.failureReason,
        completedAt: transaction.completedAt,
        createdAt: transaction.createdAt,
        updatedAt: transaction.updatedAt,
        senderName: response['sender_profiles']?['full_name'],
        receiverName: response['receiver_profiles']?['full_name'],
      );
    } catch (error) {
      throw Exception('Failed to get transaction: $error');
    }
  }

  // Get pending transactions count
  Future<int> getPendingTransactionsCount() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      final response = await _client
          .from('transactions')
          .select('id')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .eq('transaction_status', 'pending')
          .count();

      return response.count ?? 0;
    } catch (error) {
      return 0;
    }
  }

  // Retry failed transaction
  Future<Transaction> retryTransaction(String transactionId) async {
    try {
      final response = await _client
          .from('transactions')
          .update({
            'transaction_status': 'pending',
            'failure_reason': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId)
          .eq('transaction_status', 'failed')
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (error) {
      throw Exception('Retry transaction failed: $error');
    }
  }

  // Get monthly transaction summary
  Future<Map<String, dynamic>> getMonthlyTransactionSummary({
    DateTime? month,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final targetMonth = month ?? DateTime.now();
      final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
      final endOfMonth =
          DateTime(targetMonth.year, targetMonth.month + 1, 0, 23, 59, 59);

      final sentData = await _client
          .from('transactions')
          .select('amount')
          .eq('sender_id', currentUserId)
          .eq('transaction_status', 'completed')
          .gte('completed_at', startOfMonth.toIso8601String())
          .lte('completed_at', endOfMonth.toIso8601String())
          .count();

      final receivedData = await _client
          .from('transactions')
          .select('amount')
          .eq('receiver_id', currentUserId)
          .eq('transaction_status', 'completed')
          .gte('completed_at', startOfMonth.toIso8601String())
          .lte('completed_at', endOfMonth.toIso8601String())
          .count();

      return {
        'sent_count': sentData.count ?? 0,
        'received_count': receivedData.count ?? 0,
        'total_transactions': (sentData.count ?? 0) + (receivedData.count ?? 0),
      };
    } catch (error) {
      throw Exception('Failed to get transaction summary: $error');
    }
  }

  // Store offline transaction for later sync
  Future<void> storeOfflineTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _client.from('offline_transactions').insert({
        'user_id': currentUserId,
        'transaction_data': transactionData,
        'sync_status': 'pending',
      });
    } catch (error) {
      throw Exception('Failed to store offline transaction: $error');
    }
  }

  // Sync offline transactions
  Future<List<Transaction>> syncOfflineTransactions() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final offlineTransactions = await _client
          .from('offline_transactions')
          .select()
          .eq('user_id', currentUserId)
          .eq('sync_status', 'pending')
          .order('created_at');

      final syncedTransactions = <Transaction>[];

      for (final offline in offlineTransactions) {
        try {
          final transactionData =
              offline['transaction_data'] as Map<String, dynamic>;

          // Create the transaction
          final response = await _client
              .from('transactions')
              .insert(transactionData)
              .select()
              .single();

          syncedTransactions.add(Transaction.fromJson(response));

          // Mark as synced
          await _client.from('offline_transactions').update({
            'sync_status': 'completed',
            'synced_at': DateTime.now().toIso8601String(),
          }).eq('id', offline['id']);
        } catch (error) {
          // Mark as failed
          await _client.from('offline_transactions').update({
            'sync_status': 'failed',
            'retry_count': (offline['retry_count'] as int) + 1,
          }).eq('id', offline['id']);
        }
      }

      return syncedTransactions;
    } catch (error) {
      throw Exception('Failed to sync offline transactions: $error');
    }
  }
}