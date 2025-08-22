import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/amount_input_widget.dart';
import './widgets/memo_input_widget.dart';
import './widgets/recipient_selection_widget.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({Key? key}) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final ScrollController _scrollController = ScrollController();

  // Form state
  String _selectedRecipient = '';
  double _selectedAmount = 0.0;
  String _memo = '';
  bool _isGeneratingQR = false;

  // Mock user balance
  final double _currentBalance = 2847.50;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _selectedRecipient.isNotEmpty &&
        _selectedAmount > 0 &&
        _selectedAmount <= _currentBalance &&
        _isValidRecipient(_selectedRecipient);
  }

  bool _isValidRecipient(String recipient) {
    if (recipient.isEmpty) return false;

    // Check if it's a valid email
    if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(recipient)) {
      return true;
    }

    // Check if it's a valid phone number
    final phoneRegex = RegExp(r'^\+?1?\d{10,14}$');
    final cleanPhone = recipient.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phoneRegex.hasMatch(cleanPhone)) {
      return true;
    }

    // Check if it's a recipient from recent list (contains name and phone/email)
    if (recipient.contains('(') && recipient.contains(')')) {
      return true;
    }

    return false;
  }

  void _onRecipientSelected(String recipient) {
    setState(() {
      _selectedRecipient = recipient;
    });
  }

  void _onAmountChanged(double amount) {
    setState(() {
      _selectedAmount = amount;
    });
  }

  void _onMemoChanged(String memo) {
    setState(() {
      _memo = memo;
    });
  }

  Future<void> _generateQRCode() async {
    if (!_isFormValid) return;

    setState(() {
      _isGeneratingQR = true;
    });

    try {
      // Simulate QR code generation with encryption
      await Future.delayed(const Duration(seconds: 2));

      // Create transaction data for QR code
      final transactionData = {
        'id': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'recipient': _selectedRecipient,
        'amount': _selectedAmount,
        'memo': _memo,
        'timestamp': DateTime.now().toIso8601String(),
        'sender_balance': _currentBalance,
      };

      // Navigate to QR display screen with transaction data
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/qr-code-display-screen',
          arguments: transactionData,
        );
      }
    } catch (e) {
      // Handle QR generation error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate QR code. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _generateQRCode,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingQR = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedAmount > 0 ||
        _selectedRecipient.isNotEmpty ||
        _memo.isNotEmpty) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Discard Changes?',
                style: AppTheme.lightTheme.textTheme.titleLarge,
              ),
              content: Text(
                'You have unsaved changes. Are you sure you want to go back?',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Discard',
                    style:
                        TextStyle(color: AppTheme.lightTheme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
          title: Text(
            'Send Money',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          actions: [
            // Help/Info button
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'How it works',
                      style: AppTheme.lightTheme.textTheme.titleLarge,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Enter recipient\'s phone or email',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '2. Set the amount to send',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '3. Add an optional note',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '4. Generate QR code for offline payment',
                          style: AppTheme.lightTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              icon: CustomIconWidget(
                iconName: 'help_outline',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2.h),

                      // Current balance display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.lightTheme.primaryColor,
                              AppTheme.lightTheme.primaryColor
                                  .withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Balance',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              '\$${_currentBalance.toStringAsFixed(2)}',
                              style: AppTheme.lightTheme.textTheme.headlineLarge
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 4.h),

                      // Recipient selection
                      RecipientSelectionWidget(
                        onRecipientSelected: _onRecipientSelected,
                        selectedRecipient: _selectedRecipient,
                      ),

                      SizedBox(height: 4.h),

                      // Amount input
                      Text(
                        'Amount',
                        style:
                            AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      AmountInputWidget(
                        onAmountChanged: _onAmountChanged,
                        currentBalance: _currentBalance,
                        selectedAmount: _selectedAmount,
                      ),

                      SizedBox(height: 4.h),

                      // Memo input
                      MemoInputWidget(
                        onMemoChanged: _onMemoChanged,
                        initialMemo: _memo,
                      ),

                      SizedBox(height: 6.h),
                    ],
                  ),
                ),
              ),

              // Bottom action area
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Transaction summary
                    if (_isFormValid) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaction Summary',
                              style: AppTheme.lightTheme.textTheme.titleSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.lightTheme.primaryColor,
                              ),
                            ),
                            SizedBox(height: 1.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Amount:',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodyMedium,
                                ),
                                Text(
                                  '\$${_selectedAmount.toStringAsFixed(2)}',
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_memo.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Note:',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodyMedium,
                                  ),
                                  SizedBox(width: 2.w),
                                  Expanded(
                                    child: Text(
                                      _memo,
                                      style: AppTheme
                                          .lightTheme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Generate QR Code button
                    SizedBox(
                      width: double.infinity,
                      height: 7.h,
                      child: ElevatedButton(
                        onPressed: _isFormValid && !_isGeneratingQR
                            ? _generateQRCode
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormValid
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.3),
                          foregroundColor: Colors.white,
                          elevation: _isFormValid ? 2.0 : 0.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isGeneratingQR
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 5.w,
                                    height: 5.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Encrypting Transaction...',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'qr_code',
                                    color: Colors.white,
                                    size: 6.w,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Generate QR Code',
                                    style: AppTheme
                                        .lightTheme.textTheme.titleMedium
                                        ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Offline indicator
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'wifi_off',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Works offline • Syncs when connected',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
