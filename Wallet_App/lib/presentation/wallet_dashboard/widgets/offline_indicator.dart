import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class OfflineIndicator extends StatelessWidget {
  final bool isOffline;
  final int pendingTransactionCount;

  const OfflineIndicator({
    Key? key,
    required this.isOffline,
    required this.pendingTransactionCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isOffline
        ? Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.warningLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warningLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'wifi_off',
                  color: AppTheme.warningLight,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Mode',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.warningLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (pendingTransactionCount > 0) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          '$pendingTransactionCount transaction${pendingTransactionCount > 1 ? 's' : ''} pending sync',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.warningLight,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.warningLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                        ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }
}
