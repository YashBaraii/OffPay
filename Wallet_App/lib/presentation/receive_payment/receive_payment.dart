import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/amount_input_section.dart';
import './widgets/payment_status_widget.dart';
import './widgets/qr_code_display.dart';
import './widgets/qr_timer_widget.dart';
import './widgets/sharing_options_widget.dart';
import './widgets/user_profile_header.dart';

class ReceivePayment extends StatefulWidget {
  const ReceivePayment({Key? key}) : super(key: key);

  @override
  State<ReceivePayment> createState() => _ReceivePaymentState();
}

class _ReceivePaymentState extends State<ReceivePayment>
    with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  bool _isAnyAmount = false;
  bool _isGeneratingQR = false;
  String _qrData = '';
  String _paymentStatus = 'waiting';
  int _remainingSeconds = 300; // 5 minutes
  Timer? _timer;
  Timer? _statusTimer;
  Map<String, dynamic>? _senderDetails;
  String? _transactionId;

  // Mock user profile data
  final Map<String, dynamic> _userProfile = {
    "userId": "UP123456789",
    "name": "Sarah Johnson",
    "phoneNumber": "+1 (555) 123-4567",
    "profilePicture":
        "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
    "walletBalance": 2450.75,
  };

  // Mock sender details for completed payment
  final List<Map<String, dynamic>> _mockSenders = [
    {
      "name": "Michael Rodriguez",
      "phoneNumber": "+1 (555) 987-6543",
      "amount": "125.50",
      "userId": "UP987654321",
    },
    {
      "name": "Emma Thompson",
      "phoneNumber": "+1 (555) 456-7890",
      "amount": "75.25",
      "userId": "UP456789123",
    },
    {
      "name": "David Chen",
      "phoneNumber": "+1 (555) 234-5678",
      "amount": "200.00",
      "userId": "UP789123456",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _preventScreenLock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _preventScreenLock() {
    // Keep screen awake during payment waiting
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = 300; // Reset to 5 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _refreshQRCode();
          }
        });
      }
    });
  }

  void _generateQRCode() {
    if (_isGeneratingQR) return;

    setState(() {
      _isGeneratingQR = true;
      _paymentStatus = 'waiting';
      _senderDetails = null;
      _transactionId = null;
    });

    // Simulate QR code generation
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        final amount = _isAnyAmount ? 'any' : _amountController.text;
        final qrPayload = {
          'type': 'payment_request',
          'userId': _userProfile['userId'],
          'userName': _userProfile['name'],
          'amount': amount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'requestId': _generateRequestId(),
        };

        setState(() {
          _qrData = jsonEncode(qrPayload);
          _isGeneratingQR = false;
        });

        // Simulate payment status updates
        _simulatePaymentFlow();
      }
    });
  }

  void _simulatePaymentFlow() {
    // Simulate random payment completion after 10-30 seconds
    final random = Random();
    final delay = 10 + random.nextInt(20); // 10-30 seconds

    _statusTimer?.cancel();
    _statusTimer = Timer(Duration(seconds: delay), () {
      if (mounted && _paymentStatus == 'waiting') {
        // Randomly choose success or processing
        final shouldComplete = random.nextBool();

        if (shouldComplete) {
          _completePayment();
        } else {
          setState(() {
            _paymentStatus = 'processing';
          });

          // Complete after processing
          Timer(const Duration(seconds: 3), () {
            if (mounted) {
              _completePayment();
            }
          });
        }
      }
    });
  }

  void _completePayment() {
    final random = Random();
    final sender = _mockSenders[random.nextInt(_mockSenders.length)];
    final amount = _isAnyAmount
        ? (50 + random.nextInt(200)).toString() +
            '.${random.nextInt(100).toString().padLeft(2, '0')}'
        : _amountController.text;

    setState(() {
      _paymentStatus = 'completed';
      _senderDetails = {
        ...sender,
        'amount': amount,
      };
      _transactionId = _generateTransactionId();
    });

    // Provide haptic feedback
    HapticFeedback.mediumImpact();

    // Show success notification
    _showPaymentCompletedNotification();
  }

  void _showPaymentCompletedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payment Received!',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'From ${_senderDetails!['name']} - \$${_senderDetails!['amount']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, '/transaction-history');
          },
        ),
      ),
    );
  }

  String _generateRequestId() {
    final random = Random();
    return 'REQ${DateTime.now().millisecondsSinceEpoch}${random.nextInt(1000)}';
  }

  String _generateTransactionId() {
    final random = Random();
    return 'TXN${DateTime.now().millisecondsSinceEpoch}${random.nextInt(10000)}';
  }

  void _refreshQRCode() {
    _startTimer();
    if (_qrData.isNotEmpty) {
      _generateQRCode();
    }
  }

  void _onAmountChanged() {
    if (_qrData.isNotEmpty) {
      _generateQRCode();
    }
  }

  void _onAnyAmountToggle(bool value) {
    setState(() {
      _isAnyAmount = value;
      if (value) {
        _amountController.clear();
      }
    });
    if (_qrData.isNotEmpty) {
      _generateQRCode();
    }
  }

  String _getPaymentLink() {
    if (_qrData.isEmpty) return '';
    final encodedData = base64Encode(utf8.encode(_qrData));
    return 'https://offlinepay.app/pay?data=$encodedData';
  }

  void _saveToGallery() {
    // Simulate save to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: Colors.white,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'QR code saved to gallery',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareQRCode() {
    // Simulate share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'share',
              color: Colors.white,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Opening share options...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _printQRCode() {
    // Simulate print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'print',
              color: Colors.white,
              size: 4.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Preparing to print...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Receive Payment',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/transaction-history'),
            icon: CustomIconWidget(
              iconName: 'history',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Header
              UserProfileHeader(userProfile: _userProfile),

              SizedBox(height: 3.h),

              // Amount Input Section
              AmountInputSection(
                amountController: _amountController,
                isAnyAmount: _isAnyAmount,
                onAnyAmountToggle: _onAnyAmountToggle,
                onAmountChanged: _onAmountChanged,
              ),

              SizedBox(height: 3.h),

              // Generate QR Button
              if (_qrData.isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingQR ? null : _generateQRCode,
                    icon: _isGeneratingQR
                        ? SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : CustomIconWidget(
                            iconName: 'qr_code',
                            color: Colors.white,
                            size: 5.w,
                          ),
                    label: Text(
                      _isGeneratingQR ? 'Generating...' : 'Generate QR Code',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.w),
                      ),
                    ),
                  ),
                ),

              // QR Code Display
              if (_qrData.isNotEmpty || _isGeneratingQR) ...[
                QrCodeDisplay(
                  qrData: _qrData,
                  isGenerating: _isGeneratingQR,
                ),

                SizedBox(height: 3.h),

                // QR Timer
                QrTimerWidget(
                  remainingSeconds: _remainingSeconds,
                  onRefresh: _refreshQRCode,
                  isActive: _qrData.isNotEmpty,
                ),

                SizedBox(height: 3.h),

                // Sharing Options
                if (_qrData.isNotEmpty)
                  SharingOptionsWidget(
                    qrData: _qrData,
                    paymentLink: _getPaymentLink(),
                    onSaveToGallery: _saveToGallery,
                    onShare: _shareQRCode,
                    onPrint: _printQRCode,
                  ),

                SizedBox(height: 3.h),

                // Payment Status
                PaymentStatusWidget(
                  status: _paymentStatus,
                  senderDetails: _senderDetails,
                  transactionId: _transactionId,
                ),
              ],

              SizedBox(height: 10.h), // Bottom padding
            ],
          ),
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, '/wallet-dashboard'),
                icon: CustomIconWidget(
                  iconName: 'home',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 4.w,
                ),
                label: Text('Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/send-payment'),
                icon: CustomIconWidget(
                  iconName: 'send',
                  color: Colors.white,
                  size: 4.w,
                ),
                label: Text('Send Money'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
