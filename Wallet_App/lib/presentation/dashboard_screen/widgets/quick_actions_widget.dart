import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onSendMoney;
  final VoidCallback onRequestMoney;
  final VoidCallback onScanQR;

  const QuickActionsWidget({
    Key? key,
    required this.onSendMoney,
    required this.onRequestMoney,
    required this.onScanQR,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: 'send',
            label: 'Send Money',
            onTap: onSendMoney,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          _buildActionButton(
            icon: 'request_page',
            label: 'Request Money',
            onTap: onRequestMoney,
            color: AppTheme.lightTheme.colorScheme.secondary,
          ),
          _buildActionButton(
            icon: 'qr_code_scanner',
            label: 'Scan QR',
            onTap: onScanQR,
            color: AppTheme.getAccentColor(isLight: true),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          padding: EdgeInsets.symmetric(vertical: 3.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: icon,
                color: color,
                size: 6.w,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
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
