import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BalanceCardWidget extends StatefulWidget {
  final double balance;
  final String lastSyncTime;
  final bool isOnline;
  final VoidCallback onToggleVisibility;
  final bool isBalanceVisible;

  const BalanceCardWidget({
    Key? key,
    required this.balance,
    required this.lastSyncTime,
    required this.isOnline,
    required this.onToggleVisibility,
    required this.isBalanceVisible,
  }) : super(key: key);

  @override
  State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  if (!widget.isOnline)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: AppTheme.warningLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomIconWidget(
                            iconName: 'wifi_off',
                            color: AppTheme.warningLight,
                            size: 3.w,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            'Offline',
                            style: AppTheme.lightTheme.textTheme.labelSmall
                                ?.copyWith(
                              color: AppTheme.warningLight,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(width: 2.w),
                  GestureDetector(
                    onTap: widget.onToggleVisibility,
                    child: CustomIconWidget(
                      iconName: widget.isBalanceVisible
                          ? 'visibility'
                          : 'visibility_off',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 5.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          widget.isBalanceVisible
              ? Text(
                  '\$${widget.balance.toStringAsFixed(2)}',
                  style: AppTheme.getAmountTextStyle(
                    isLight: true,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Text(
                  '••••••',
                  style: AppTheme.getAmountTextStyle(
                    isLight: true,
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
          SizedBox(height: 1.h),
          Text(
            'Last updated: ${widget.lastSyncTime}',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}
