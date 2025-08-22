import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class EmptyStateWidget extends StatelessWidget {
  final String type;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    Key? key,
    required this.type,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            SizedBox(height: 3.h),
            Text(
              _getTitle(),
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              _getDescription(),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              SizedBox(height: 4.h),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                ),
                child: Text(_getActionText()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    String iconName;
    Color iconColor;

    switch (type) {
      case 'no_transactions':
        iconName = 'receipt_long';
        iconColor = AppTheme.lightTheme.colorScheme.primary;
        break;
      case 'no_search_results':
        iconName = 'search_off';
        iconColor = AppTheme.lightTheme.colorScheme.secondary;
        break;
      case 'network_sync_required':
        iconName = 'sync_problem';
        iconColor = AppTheme.lightTheme.colorScheme.error;
        break;
      default:
        iconName = 'help_outline';
        iconColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: iconName,
          color: iconColor,
          size: 10.w,
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case 'no_transactions':
        return 'No Transactions Yet';
      case 'no_search_results':
        return 'No Results Found';
      case 'network_sync_required':
        return 'Sync Required';
      default:
        return 'Nothing Here';
    }
  }

  String _getDescription() {
    switch (type) {
      case 'no_transactions':
        return 'Start making payments to see your transaction history here. Your first transaction is just a QR scan away!';
      case 'no_search_results':
        return 'We couldn\'t find any transactions matching your search. Try adjusting your search terms or filters.';
      case 'network_sync_required':
        return 'Some transactions need to be synced with the server. Connect to the internet to update your history.';
      default:
        return 'There\'s nothing to display at the moment.';
    }
  }

  String _getActionText() {
    switch (type) {
      case 'no_transactions':
        return 'Send Money';
      case 'no_search_results':
        return 'Clear Search';
      case 'network_sync_required':
        return 'Retry Sync';
      default:
        return 'Refresh';
    }
  }
}
