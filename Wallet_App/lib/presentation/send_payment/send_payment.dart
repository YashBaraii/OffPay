import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/amount_input_widget.dart';
import './widgets/confirmation_modal_widget.dart';
import './widgets/payment_note_widget.dart';
import './widgets/payment_summary_widget.dart';
import './widgets/recipient_info_widget.dart';

class SendPayment extends StatefulWidget {
  const SendPayment({Key? key}) : super(key: key);

  @override
  State<SendPayment> createState() => _SendPaymentState();
}

class _SendPaymentState extends State<SendPayment> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _amountFocusNode = FocusNode();

  // Mock data for current user and recipient
  final Map<String, dynamic> _currentUser = {
    'id': 'user_001',
    'name': 'John Smith',
    'phoneNumber': '+1 (555) 123-4567',
    'balance': 1250.75,
    'upiId': 'johnsmith@offlinepay',
  };

  Map<String, dynamic> _recipientData = {
    'id': 'user_002',
    'name': 'Sarah Johnson',
    'phoneNumber': '+1 (555) 987-6543',
    'upiId': 'sarahjohnson@offlinepay',
    'profilePicture':
        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=400&fit=crop&crop=face',
  };

  // Transaction data
  double _enteredAmount = 0.0;
  double _processingFee = 0.0;
  String _errorMessage = '';
  bool _isProcessing = false;
  bool _showConfirmation = false;
  bool _isOnline = true;

  // Mock transaction history for duplicate prevention
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'id': 'txn_001',
      'recipientId': 'user_003',
      'amount': 25.50,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'status': 'completed',
    },
    {
      'id': 'txn_002',
      'recipientId': 'user_004',
      'amount': 100.00,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'status': 'pending',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipientFromQR();
    _checkNetworkStatus();
    _amountFocusNode.addListener(_onAmountFocusChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _loadRecipientFromQR() {
    // Simulate loading recipient data from QR code scan
    // In real implementation, this would come from navigation arguments
    final Map<String, dynamic>? qrData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (qrData != null) {
      setState(() {
        _recipientData = {
          'id': qrData['userId'] ?? 'user_002',
          'name': qrData['name'] ?? 'Sarah Johnson',
          'phoneNumber': qrData['phoneNumber'] ?? '+1 (555) 987-6543',
          'upiId': qrData['upiId'] ?? 'sarahjohnson@offlinepay',
          'profilePicture': qrData['profilePicture'],
        };
      });
    }
  }

  void _checkNetworkStatus() {
    // Simulate network status check
    // In real implementation, use connectivity_plus package
    setState(() {
      _isOnline = true; // Mock online status
    });
  }

  void _onAmountFocusChanged() {
    if (_amountFocusNode.hasFocus) {
      // Scroll to ensure amount field is visible when keyboard appears
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          200.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _onAmountChanged(String value) {
    setState(() {
      _enteredAmount = double.tryParse(value) ?? 0.0;
      _processingFee = _calculateProcessingFee(_enteredAmount);
      _errorMessage = _validateAmount(_enteredAmount);
    });
  }

  double _calculateProcessingFee(double amount) {
    // Mock fee calculation: 1% with minimum $0.50 and maximum $5.00
    if (amount <= 0) return 0.0;
    double fee = amount * 0.01;
    return fee.clamp(0.50, 5.00);
  }

  String _validateAmount(double amount) {
    if (amount <= 0) return '';
    if (amount > _currentUser['balance']) {
      return 'Insufficient balance';
    }
    if (amount < 1.0) {
      return 'Minimum amount is \$1.00';
    }
    if (amount > 5000.0) {
      return 'Maximum amount is \$5,000.00';
    }
    if (_isDuplicateTransaction(amount)) {
      return 'Similar transaction sent recently';
    }
    return '';
  }

  bool _isDuplicateTransaction(double amount) {
    // Check for duplicate transactions in the last 5 minutes
    final DateTime fiveMinutesAgo =
        DateTime.now().subtract(const Duration(minutes: 5));
    return _recentTransactions.any((transaction) =>
        (transaction['recipientId'] as String) == _recipientData['id'] &&
        (transaction['amount'] as double) == amount &&
        (transaction['timestamp'] as DateTime).isAfter(fiveMinutesAgo));
  }

  bool _canSendPayment() {
    return _enteredAmount > 0 &&
        _errorMessage.isEmpty &&
        !_isProcessing &&
        _recipientData['id'] != null;
  }

  void _onEditRecipient() {
    // Show dialog to edit recipient information
    showDialog(
      context: context,
      builder: (context) => _buildEditRecipientDialog(),
    );
  }

  Widget _buildEditRecipientDialog() {
    final TextEditingController nameController =
        TextEditingController(text: _recipientData['name']);
    final TextEditingController phoneController =
        TextEditingController(text: _recipientData['phoneNumber']);

    return AlertDialog(
      title: Text(
        'Edit Recipient',
        style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _recipientData['name'] = nameController.text;
              _recipientData['phoneNumber'] = phoneController.text;
            });
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showConfirmationModal() {
    setState(() {
      _showConfirmation = true;
    });
  }

  void _hideConfirmationModal() {
    setState(() {
      _showConfirmation = false;
    });
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Simulate biometric authentication
      await _authenticateWithBiometrics();

      // Simulate payment processing
      await _sendPaymentRequest();

      // Show success and navigate back
      _showSuccessMessage();

      // Wait a moment then navigate back
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/wallet-dashboard');
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showConfirmation = false;
        });
      }
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    // Simulate biometric authentication delay
    await Future.delayed(const Duration(seconds: 1));

    // In real implementation, use local_auth package
    // For demo purposes, we'll simulate success
    // Uncomment below line to simulate authentication failure
    // throw Exception('Biometric authentication failed');
  }

  Future<void> _sendPaymentRequest() async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Create transaction record
    final Map<String, dynamic> transaction = {
      'id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'senderId': _currentUser['id'],
      'recipientId': _recipientData['id'],
      'amount': _enteredAmount,
      'fee': _processingFee,
      'note': _noteController.text,
      'timestamp': DateTime.now(),
      'status': _isOnline ? 'completed' : 'pending',
      'isOffline': !_isOnline,
    };

    // Add to recent transactions
    _recentTransactions.insert(0, transaction);

    // Update balance
    _currentUser['balance'] =
        (_currentUser['balance'] as double) - (_enteredAmount + _processingFee);

    // In real implementation:
    // - Store transaction in local database
    // - Queue for sync if offline
    // - Update local wallet balance
    // - Send to backend API if online
  }

  void _showSuccessMessage() {
    Fluttertoast.showToast(
      msg: 'Payment sent successfully!',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
      textColor: Colors.white,
    );
  }

  void _showErrorMessage(String message) {
    Fluttertoast.showToast(
      msg: 'Payment failed: $message',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.error,
      textColor: Colors.white,
    );
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Send Payment',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          onPressed: _onCancel,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4.w),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: _isOnline
                  ? AppTheme.lightTheme.colorScheme.tertiaryContainer
                  : AppTheme.lightTheme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(5.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: _isOnline ? 'wifi' : 'wifi_off',
                  color: _isOnline
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : AppTheme.lightTheme.colorScheme.error,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: _isOnline
                        ? AppTheme.lightTheme.colorScheme.tertiary
                        : AppTheme.lightTheme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipient Information
                RecipientInfoWidget(
                  recipientData: _recipientData,
                  onEditTap: _onEditRecipient,
                ),
                SizedBox(height: 4.h),

                // Amount Input
                AmountInputWidget(
                  controller: _amountController,
                  currentBalance: _currentUser['balance'] as double,
                  onAmountChanged: _onAmountChanged,
                  errorMessage: _errorMessage.isNotEmpty ? _errorMessage : null,
                ),
                SizedBox(height: 4.h),

                // Payment Note
                PaymentNoteWidget(
                  controller: _noteController,
                  maxLength: 100,
                ),
                SizedBox(height: 4.h),

                // Payment Summary (only show if amount is entered)
                if (_enteredAmount > 0) ...[
                  PaymentSummaryWidget(
                    recipientData: _recipientData,
                    amount: _enteredAmount,
                    fees: _processingFee,
                    currentBalance: _currentUser['balance'] as double,
                    note: _noteController.text,
                  ),
                  SizedBox(height: 4.h),
                ],

                // Offline notice
                if (!_isOnline) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.errorContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3.w),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'info',
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 5.w,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'You\'re offline. Payment will be queued and sent when connection is restored.',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                ],

                // Bottom spacing for buttons
                SizedBox(height: 20.h),
              ],
            ),
          ),

          // Bottom Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Send Money Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _canSendPayment() ? _showConfirmationModal : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                        ),
                        child: _isProcessing
                            ? SizedBox(
                                height: 6.w,
                                width: 6.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'send',
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    size: 5.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    'Send Money',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: AppTheme
                                          .lightTheme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : _onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3.w),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Confirmation Modal
          if (_showConfirmation)
            ConfirmationModalWidget(
              recipientData: _recipientData,
              amount: _enteredAmount,
              fees: _processingFee,
              note: _noteController.text,
              onConfirm: _processPayment,
              onCancel: _hideConfirmationModal,
              isProcessing: _isProcessing,
            ),
        ],
      ),
    );
  }
}
