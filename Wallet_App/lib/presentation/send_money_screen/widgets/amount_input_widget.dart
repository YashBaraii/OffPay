import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AmountInputWidget extends StatefulWidget {
  final Function(double) onAmountChanged;
  final double currentBalance;
  final double? selectedAmount;

  const AmountInputWidget({
    Key? key,
    required this.onAmountChanged,
    required this.currentBalance,
    this.selectedAmount,
  }) : super(key: key);

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _hasInsufficientFunds = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAmount != null && widget.selectedAmount! > 0) {
      _amountController.text = widget.selectedAmount!.toStringAsFixed(2);
    }
    _amountFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) {
      widget.onAmountChanged(0.0);
      setState(() {
        _hasInsufficientFunds = false;
      });
      return;
    }

    final amount = double.tryParse(value) ?? 0.0;
    widget.onAmountChanged(amount);

    setState(() {
      _hasInsufficientFunds = amount > widget.currentBalance;
    });
  }

  void _addQuickAmount(double amount) {
    final newAmount = (double.tryParse(_amountController.text) ?? 0.0) + amount;
    if (newAmount <= widget.currentBalance) {
      _amountController.text = newAmount.toStringAsFixed(2);
      _onAmountChanged(_amountController.text);
    }
  }

  void _setQuickAmount(double amount) {
    if (amount <= widget.currentBalance) {
      _amountController.text = amount.toStringAsFixed(2);
      _onAmountChanged(_amountController.text);
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final currentAmount = double.tryParse(_amountController.text) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount input field
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: _hasInsufficientFunds
                  ? AppTheme.lightTheme.colorScheme.error
                  : _amountFocusNode.hasFocus
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
              width: _amountFocusNode.hasFocus || _hasInsufficientFunds
                  ? 2.0
                  : 1.0,
            ),
          ),
          child: Column(
            children: [
              // Currency symbol and amount input
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Row(
                  children: [
                    Text(
                      '\$',
                      style:
                          AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                        color: _hasInsufficientFunds
                            ? AppTheme.lightTheme.colorScheme.error
                            : AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        onChanged: _onAmountChanged,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: AppTheme.lightTheme.textTheme.headlineLarge
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTheme.lightTheme.textTheme.headlineLarge
                            ?.copyWith(
                          color: _hasInsufficientFunds
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ],
                ),
              ),

              // Balance information
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _hasInsufficientFunds
                      ? AppTheme.lightTheme.colorScheme.error
                          .withValues(alpha: 0.1)
                      : AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16.0),
                    bottomRight: Radius.circular(16.0),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: _hasInsufficientFunds
                          ? 'warning'
                          : 'account_balance_wallet',
                      color: _hasInsufficientFunds
                          ? AppTheme.lightTheme.colorScheme.error
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _hasInsufficientFunds
                          ? 'Insufficient funds'
                          : 'Available balance: ${_formatCurrency(widget.currentBalance)}',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: _hasInsufficientFunds
                            ? AppTheme.lightTheme.colorScheme.error
                            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight: _hasInsufficientFunds
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                    if (!_hasInsufficientFunds && currentAmount > 0) ...[
                      const Spacer(),
                      Text(
                        'Remaining: ${_formatCurrency(widget.currentBalance - currentAmount)}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 3.h),

        // Quick amount buttons
        Text(
          'Quick Amounts',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // Quick amount grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 2.w,
          mainAxisSpacing: 1.h,
          childAspectRatio: 2.5,
          children: [
            _buildQuickAmountButton(10.0),
            _buildQuickAmountButton(25.0),
            _buildQuickAmountButton(50.0),
            _buildQuickAmountButton(100.0),
          ],
        ),

        SizedBox(height: 2.h),

        // Preset percentage buttons
        Row(
          children: [
            Expanded(
              child:
                  _buildPercentageButton('25%', widget.currentBalance * 0.25),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPercentageButton('50%', widget.currentBalance * 0.5),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: _buildPercentageButton('Max', widget.currentBalance),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(double amount) {
    final isDisabled = amount > widget.currentBalance;

    return GestureDetector(
      onTap: isDisabled ? null : () => _setQuickAmount(amount),
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled
              ? AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5)
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isDisabled
                ? AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)
                : AppTheme.lightTheme.colorScheme.outline,
          ),
        ),
        child: Center(
          child: Text(
            _formatCurrency(amount),
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: isDisabled
                  ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.5)
                  : AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageButton(String label, double amount) {
    final isDisabled = amount > widget.currentBalance || amount <= 0;

    return GestureDetector(
      onTap: isDisabled ? null : () => _setQuickAmount(amount),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isDisabled
              ? AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5)
              : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isDisabled
                ? AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3)
                : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: isDisabled
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5)
                    : AppTheme.lightTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              _formatCurrency(amount),
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isDisabled
                    ? AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5)
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
