import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../models/wallet_account.dart';
import './supabase_service.dart';

class WalletService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get user's wallet accounts
  Future<List<WalletAccount>> getUserWallets({String? userId}) async {
    try {
      final currentUserId = userId ?? _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client
          .from('wallet_accounts')
          .select()
          .eq('user_id', currentUserId)
          .eq('is_active', true)
          .order('created_at');

      return (response as List)
          .map((wallet) => WalletAccount.fromJson(wallet))
          .toList();
    } catch (error) {
      throw Exception('Failed to get wallets: $error');
    }
  }

  // Get primary wallet for user
  Future<WalletAccount?> getPrimaryWallet({String? userId}) async {
    try {
      final wallets = await getUserWallets(userId: userId);
      return wallets.isNotEmpty ? wallets.first : null;
    } catch (error) {
      throw Exception('Failed to get primary wallet: $error');
    }
  }

  // Get wallet by account number
  Future<WalletAccount?> getWalletByAccountNumber(String accountNumber) async {
    try {
      final response = await _client
          .from('wallet_accounts')
          .select()
          .eq('account_number', accountNumber)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? WalletAccount.fromJson(response) : null;
    } catch (error) {
      throw Exception('Failed to find wallet: $error');
    }
  }

  // Update wallet limits
  Future<WalletAccount> updateWalletLimits({
    required String walletId,
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (dailyLimit != null) updateData['daily_limit'] = dailyLimit;
      if (monthlyLimit != null) updateData['monthly_limit'] = monthlyLimit;

      final response = await _client
          .from('wallet_accounts')
          .update(updateData)
          .eq('id', walletId)
          .eq('user_id', currentUserId)
          .select()
          .single();

      return WalletAccount.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update wallet limits: $error');
    }
  }

  // Check if user has sufficient balance
  Future<bool> hasSufficientBalance({
    required String walletId,
    required double amount,
  }) async {
    try {
      final response = await _client
          .from('wallet_accounts')
          .select('balance')
          .eq('id', walletId)
          .single();

      final balance = (response['balance'] as num).toDouble();
      return balance >= amount;
    } catch (error) {
      throw Exception('Failed to check balance: $error');
    }
  }

  // Get wallet balance
  Future<double> getWalletBalance(String walletId) async {
    try {
      final response = await _client
          .from('wallet_accounts')
          .select('balance')
          .eq('id', walletId)
          .single();

      return (response['balance'] as num).toDouble();
    } catch (error) {
      throw Exception('Failed to get wallet balance: $error');
    }
  }

  // Find user by account number or QR code
  Future<UserProfile?> findUserByIdentifier(String identifier) async {
    try {
      // Try to find by account number first
      var response = await _client
          .from('wallet_accounts')
          .select('user_id, user_profiles!inner(*)')
          .eq('account_number', identifier)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response['user_profiles']);
      }

      // Try to find by QR code
      response = await _client
          .from('user_profiles')
          .select()
          .eq('qr_code', identifier)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? UserProfile.fromJson(response) : null;
    } catch (error) {
      throw Exception('Failed to find user: $error');
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStatistics(String walletId) async {
    try {
      // Get transaction counts and amounts
      final sentData = await _client
          .from('transactions')
          .select('amount')
          .eq('sender_wallet_id', walletId)
          .eq('transaction_status', 'completed')
          .count();

      final receivedData = await _client
          .from('transactions')
          .select('amount')
          .eq('receiver_wallet_id', walletId)
          .eq('transaction_status', 'completed')
          .count();

      final pendingData = await _client
          .from('transactions')
          .select('amount')
          .or('sender_wallet_id.eq.$walletId,receiver_wallet_id.eq.$walletId')
          .eq('transaction_status', 'pending')
          .count();

      return {
        'sent_transactions': sentData.count ?? 0,
        'received_transactions': receivedData.count ?? 0,
        'pending_transactions': pendingData.count ?? 0,
      };
    } catch (error) {
      throw Exception('Failed to get wallet statistics: $error');
    }
  }

  // Create new wallet (for multi-wallet support)
  Future<WalletAccount> createWallet({
    required String walletType,
    double? dailyLimit,
    double? monthlyLimit,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final response = await _client
          .from('wallet_accounts')
          .insert({
            'user_id': currentUserId,
            'wallet_type': walletType,
            'daily_limit': dailyLimit ?? 5000.00,
            'monthly_limit': monthlyLimit ?? 50000.00,
          })
          .select()
          .single();

      return WalletAccount.fromJson(response);
    } catch (error) {
      throw Exception('Failed to create wallet: $error');
    }
  }

  // Deactivate wallet
  Future<void> deactivateWallet(String walletId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _client
          .from('wallet_accounts')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', walletId)
          .eq('user_id', currentUserId);
    } catch (error) {
      throw Exception('Failed to deactivate wallet: $error');
    }
  }
}
