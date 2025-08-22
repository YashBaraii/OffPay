import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSendMoney;
  final VoidCallback onReceiveMoney;

  const ActionButtons({
    Key? key,
    required this.onSendMoney,
    required this.onReceiveMoney,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              context: context,
              title: 'Send Money',
              icon: 'send',
              onTap: onSendMoney,
              isPrimary: true,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: _buildActionButton(
              context: context,
              title: 'Receive Money',
              icon: 'qr_code',
              onTap: onReceiveMoney,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 7.h,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppTheme.lightTheme.primaryColor
              : AppTheme.lightTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: icon,
              color:
                  isPrimary ? Colors.white : AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isPrimary
                        ? Colors.white
                        : AppTheme.lightTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
