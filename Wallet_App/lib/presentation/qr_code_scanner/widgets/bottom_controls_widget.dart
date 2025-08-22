import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BottomControlsWidget extends StatefulWidget {
  final VoidCallback onGenerateQR;
  final Function(String) onAmountEntered;
  final bool showAmountInput;
  final VoidCallback onManualEntry;
  final String? scannedAmount;

  const BottomControlsWidget({
    super.key,
    required this.onGenerateQR,
    required this.onAmountEntered,
    required this.showAmountInput,
    required this.onManualEntry,
    this.scannedAmount,
  });

  @override
  State<BottomControlsWidget> createState() => _BottomControlsWidgetState();
}

class _BottomControlsWidgetState extends State<BottomControlsWidget> {
  final TextEditingController _amountController = TextEditingController();
  bool _isAmountValid = false;

  @override
  void initState() {
    super.initState();
    if (widget.scannedAmount != null) {
      _amountController.text = widget.scannedAmount!;
      _isAmountValid = true;
    }
  }

  @override
  void didUpdateWidget(BottomControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scannedAmount != null &&
        widget.scannedAmount != oldWidget.scannedAmount) {
      _amountController.text = widget.scannedAmount!;
      _isAmountValid = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value);
    setState(() {
      _isAmountValid = amount != null && amount > 0;
    });

    if (_isAmountValid) {
      widget.onAmountEntered(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Amount input field (appears after successful scan)
              if (widget.showAmountInput) ...[
                Container(
                  margin: EdgeInsets.only(bottom: 2.h),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isAmountValid
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Amount',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Text(
                            '\$',
                            style: AppTheme.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              style: AppTheme.lightTheme.textTheme.headlineSmall
                                  ?.copyWith(
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintStyle: AppTheme
                                    .lightTheme.textTheme.headlineSmall
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              onChanged: _onAmountChanged,
                            ),
                          ),
                          if (_isAmountValid)
                            CustomIconWidget(
                              iconName: 'check_circle',
                              color: AppTheme.lightTheme.colorScheme.tertiary,
                              size: 6.w,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Control buttons
              Row(
                children: [
                  // Generate QR button
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onGenerateQR,
                      child: Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomIconWidget(
                              iconName: 'qr_code',
                              color: Colors.white,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Generate QR',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 3.w),

                  // Manual entry button
                  GestureDetector(
                    onTap: widget.onManualEntry,
                    child: Container(
                      width: 12.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: 'keyboard',
                        color: Colors.white,
                        size: 6.w,
                      ),
                    ),
                  ),
                ],
              ),

              // Instruction text
              SizedBox(height: 2.h),
              Text(
                widget.showAmountInput
                    ? 'Enter payment amount and confirm transaction'
                    : 'Point camera at QR code to scan payment',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
