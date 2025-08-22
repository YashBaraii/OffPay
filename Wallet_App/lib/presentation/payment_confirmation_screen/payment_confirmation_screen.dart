import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/confirmation_message_widget.dart';
import './widgets/pin_input_dialog.dart';
import './widgets/security_info_section.dart';
import './widgets/transaction_details_card.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  const PaymentConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  bool _isProcessing = false;
  bool _showBackDialog = false;

  // Mock transaction data - in real app this would come from QR scan
  final Map<String, dynamic> _transactionData = {
    'transactionId':
        'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    'senderName': 'Sarah Johnson',
    'amount': 125.50,
    'memo': 'Payment for lunch and coffee yesterday. Thanks for covering me!',
    'timestamp': DateTime.now().subtract(Duration(minutes: 2)),
    'isEncrypted': true,
    'fees': 0.00,
    'exchangeRate': null,
  };

  // Mock credentials for PIN authentication
  final String _correctPin = '1234';
  final List<String> _validBiometricUsers = ['biometric'];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isProcessing) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
          elevation: AppTheme.lightTheme.appBarTheme.elevation,
          centerTitle: true,
          leading: _isProcessing
              ? null
              : IconButton(
                  onPressed: () => _showExitConfirmationDialog(),
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 6.w,
                  ),
                ),
          title: Text(
            'Confirm Payment',
            style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.getStatusColor('success', isLight: true)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'security',
                    color: AppTheme.getStatusColor('success', isLight: true),
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Secure',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.getStatusColor('success', isLight: true),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 2.h),

                      // Transaction Details Card
                      TransactionDetailsCard(
                        transactionData: _transactionData,
                      ),

                      SizedBox(height: 3.h),

                      // Security Information Section
                      SecurityInfoSection(
                        transactionId:
                            _transactionData['transactionId'] as String,
                        isEncrypted: _transactionData['isEncrypted'] as bool,
                      ),

                      SizedBox(height: 3.h),

                      // Confirmation Message
                      ConfirmationMessageWidget(
                        amount: _transactionData['amount'] as double,
                        senderName: _transactionData['senderName'] as String,
                        fees: _transactionData['fees'] as double?,
                        exchangeRate:
                            _transactionData['exchangeRate'] as double?,
                      ),

                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              ActionButtonsWidget(
                onAcceptPayment: _handleAcceptPayment,
                onDeclinePayment: _handleDeclinePayment,
                isProcessing: _isProcessing,
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAcceptPayment() {
    _showPinInputDialog();
  }

  void _handleDeclinePayment() {
    _showDeclineConfirmationDialog();
  }

  void _showPinInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        onPinEntered: _verifyPinAndProcessPayment,
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _verifyPinAndProcessPayment(String pin) {
    Navigator.of(context).pop(); // Close PIN dialog

    if (pin == _correctPin || _validBiometricUsers.contains(pin)) {
      _processPayment();
    } else {
      _showAuthenticationError();
    }
  }

  void _showAuthenticationError() {
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Authentication failed. Please try again.',
                style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // Show PIN dialog again after a short delay
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) {
        _showPinInputDialog();
      }
    });
  }

  void _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing with realistic steps
    await Future.delayed(Duration(milliseconds: 800));

    if (!mounted) return;

    // Simulate validation steps
    _showProcessingSteps();

    await Future.delayed(Duration(milliseconds: 2000));

    if (!mounted) return;

    // Simulate successful processing
    _handlePaymentSuccess();
  }

  void _showProcessingSteps() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 5.w,
              height: 5.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Validating encrypted transaction data...',
                style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handlePaymentSuccess() {
    setState(() {
      _isProcessing = false;
    });

    // Haptic feedback for success
    HapticFeedback.lightImpact();

    // Show success message
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
              child: Text(
                'Payment received successfully! Balance updated.',
                style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.getStatusColor('success', isLight: true),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to dashboard after success
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard-screen',
          (route) => false,
        );
      }
    });
  }

  void _showDeclineConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Text(
              'Decline Payment',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to decline this payment from ${_transactionData['senderName']}? This action cannot be undone.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDeclineConfirmed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Decline Payment'),
          ),
        ],
      ),
    );
  }

  void _handleDeclineConfirmed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: Colors.white,
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                'Payment declined. Sender will be notified.',
                style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.onSurface,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate back to receive money screen
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/receive-money-screen');
      }
    });
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'warning',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Text(
              'Cancel Transaction',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to cancel this transaction? You will need to scan the QR code again.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Stay',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel Transaction',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
