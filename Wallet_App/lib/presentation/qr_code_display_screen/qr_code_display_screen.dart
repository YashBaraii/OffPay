import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/instructions_widget.dart';
import './widgets/qr_code_widget.dart';
import './widgets/timer_widget.dart';
import './widgets/transaction_summary_card.dart';

class QrCodeDisplayScreen extends StatefulWidget {
  const QrCodeDisplayScreen({Key? key}) : super(key: key);

  @override
  State<QrCodeDisplayScreen> createState() => _QrCodeDisplayScreenState();
}

class _QrCodeDisplayScreenState extends State<QrCodeDisplayScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _remainingSeconds = 60;
  String _qrData = '';
  double? _originalBrightness;
  bool _isGeneratingQr = false;

  // Mock transaction data
  final Map<String, dynamic> _transactionData = {
    "transactionId": "TXN_${DateTime.now().millisecondsSinceEpoch}",
    "recipientName": "Sarah Johnson",
    "amount": 125.50,
    "memo": "Lunch payment - Thanks!",
    "senderWallet": "wallet_sender_123",
    "timestamp": DateTime.now().toIso8601String(),
    "currency": "USD",
    "type": "offline_transfer"
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeScreen();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _restoreScreenBrightness();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _restoreScreenBrightness();
    } else if (state == AppLifecycleState.resumed) {
      _setMaxBrightness();
    }
  }

  Future<void> _initializeScreen() async {
    await _setMaxBrightness();
    await _generateQrCode();
    _startTimer();
  }

  Future<void> _setMaxBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().current;
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      // Handle brightness control error silently
    }
  }

  Future<void> _restoreScreenBrightness() async {
    try {
      if (_originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
      }
    } catch (e) {
      // Handle brightness restore error silently
    }
  }

  Future<void> _generateQrCode() async {
    if (_isGeneratingQr) return;

    setState(() {
      _isGeneratingQr = true;
    });

    try {
      // Add security timestamp and random nonce for uniqueness
      final secureData = {
        ..._transactionData,
        "nonce": _generateNonce(),
        "expiresAt":
            DateTime.now().add(const Duration(seconds: 60)).toIso8601String(),
        "securityHash": _generateSecurityHash(),
      };

      // Encrypt the transaction data (simplified encryption for demo)
      final encryptedData = _encryptTransactionData(secureData);

      setState(() {
        _qrData = encryptedData;
        _isGeneratingQr = false;
      });

      // Provide haptic feedback
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _qrData = '';
        _isGeneratingQr = false;
      });
    }
  }

  String _generateNonce() {
    final random = Random.secure();
    return List.generate(16,
            (index) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _generateSecurityHash() {
    final random = Random.secure();
    return List.generate(32,
            (index) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _encryptTransactionData(Map<String, dynamic> data) {
    // Simplified encryption - in production, use proper AES encryption
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final base64String = base64Encode(bytes);
    return 'OFFLINEPAY_$base64String';
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Provide haptic feedback when time is running low
        if (_remainingSeconds == 15 || _remainingSeconds == 5) {
          HapticFeedback.mediumImpact();
        }
      } else {
        timer.cancel();
        _regenerateQrCode();
      }
    });
  }

  void _regenerateQrCode() {
    HapticFeedback.mediumImpact();
    _generateQrCode();
    _startTimer();
  }

  Future<void> _shareQrCode() async {
    try {
      if (_qrData.isNotEmpty) {
        await Share.share(
          'OfflinePay Payment Code: $_qrData\n\nScan this code with OfflinePay app to receive \$${_transactionData["amount"].toStringAsFixed(2)} from ${_transactionData["recipientName"]}',
          subject: 'OfflinePay Payment Code',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Unable to share QR code');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                message,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Payment?',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this payment? The QR code will become invalid.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Continue',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Cancel Payment',
              style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Share Payment',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
            icon: CustomIconWidget(
              iconName: 'close',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 3.h),

                // Transaction Summary Card
                TransactionSummaryCard(
                  recipientName: _transactionData["recipientName"] as String,
                  amount: (_transactionData["amount"] as num).toDouble(),
                  memo: _transactionData["memo"] as String?,
                ),

                SizedBox(height: 4.h),

                // QR Code Display
                Center(
                  child: QrCodeWidget(
                    qrData: _qrData,
                    onRegeneratePressed: _regenerateQrCode,
                  ),
                ),

                SizedBox(height: 4.h),

                // Instructions
                const InstructionsWidget(),

                SizedBox(height: 4.h),

                // Timer and Regenerate Button
                TimerWidget(
                  remainingSeconds: _remainingSeconds,
                  onRegeneratePressed: _regenerateQrCode,
                ),

                SizedBox(height: 4.h),

                // Action Buttons
                ActionButtonsWidget(
                  qrData: _qrData,
                  onSharePressed: _shareQrCode,
                ),

                SizedBox(height: 4.h),

                // Status Indicator
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondaryContainer
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.secondary
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Transaction pending - waiting for recipient to scan',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
