import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class QrService {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Create payment request with QR code
  Future<Map<String, dynamic>> createPaymentRequest({
    required double amount,
    String? note,
    int expiryMinutes = 60,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final expiresAt = DateTime.now().add(Duration(minutes: expiryMinutes));

      final response = await _client
          .from('payment_requests')
          .insert({
            'requester_id': currentUserId,
            'amount': amount,
            'note': note,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create payment request: $error');
    }
  }

  // Get payment request by QR code
  Future<Map<String, dynamic>?> getPaymentRequestByQrCode(String qrCode) async {
    try {
      final response = await _client
          .from('payment_requests')
          .select('*, user_profiles!inner(full_name, email)')
          .eq('qr_code', qrCode)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response;
    } catch (error) {
      throw Exception('Failed to get payment request: $error');
    }
  }

  // Mark payment request as used
  Future<void> markPaymentRequestAsUsed({
    required String qrCode,
    required String usedBy,
  }) async {
    try {
      await _client.from('payment_requests').update({
        'is_used': true,
        'used_at': DateTime.now().toIso8601String(),
        'used_by': usedBy,
      }).eq('qr_code', qrCode);
    } catch (error) {
      throw Exception('Failed to mark payment request as used: $error');
    }
  }

  // Get user's payment requests
  Future<List<Map<String, dynamic>>> getUserPaymentRequests({
    bool? isUsed,
    int limit = 10,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      var query = _client
          .from('payment_requests')
          .select()
          .eq('requester_id', currentUserId);

      if (isUsed != null) {
        query = query.eq('is_used', isUsed);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (error) {
      throw Exception('Failed to get payment requests: $error');
    }
  }

  // Validate QR code format
  bool isValidQrCode(String qrCode) {
    // Check if it matches our QR code pattern
    return qrCode.startsWith('QR') && qrCode.length >= 10;
  }

  // Generate user QR code for receiving payments
  Future<String?> getUserQrCode() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select('qr_code')
          .eq('id', currentUserId)
          .single();

      return response['qr_code'] as String?;
    } catch (error) {
      throw Exception('Failed to get user QR code: $error');
    }
  }

  // Delete expired payment requests
  Future<int> cleanupExpiredRequests() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      final response = await _client
          .from('payment_requests')
          .delete()
          .eq('requester_id', currentUserId)
          .lt('expires_at', DateTime.now().toIso8601String())
          .eq('is_used', false)
          .select()
          .count();

      return response.count ?? 0;
    } catch (error) {
      return 0;
    }
  }

  // Cancel payment request
  Future<void> cancelPaymentRequest(String paymentRequestId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _client
          .from('payment_requests')
          .delete()
          .eq('id', paymentRequestId)
          .eq('requester_id', currentUserId)
          .eq('is_used', false);
    } catch (error) {
      throw Exception('Failed to cancel payment request: $error');
    }
  }

  // Get active payment requests count
  Future<int> getActivePaymentRequestsCount() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return 0;

      final response = await _client
          .from('payment_requests')
          .select('id')
          .eq('requester_id', currentUserId)
          .eq('is_used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .count();

      return response.count ?? 0;
    } catch (error) {
      return 0;
    }
  }

  // Parse QR code data for different types
  Map<String, dynamic> parseQrCodeData(String qrCode) {
    // Check if it's a payment request QR
    if (qrCode.startsWith('QR')) {
      return {
        'type': 'payment_request',
        'qr_code': qrCode,
      };
    }

    // Check if it's a user QR (for direct payments)
    if (qrCode.startsWith('USER_')) {
      return {
        'type': 'user_qr',
        'user_id': qrCode.substring(5),
      };
    }

    // Check if it's an account number
    if (qrCode.startsWith('OPP') && qrCode.length == 10) {
      return {
        'type': 'account_number',
        'account_number': qrCode,
      };
    }

    // Default to unknown type
    return {
      'type': 'unknown',
      'data': qrCode,
    };
  }
}
