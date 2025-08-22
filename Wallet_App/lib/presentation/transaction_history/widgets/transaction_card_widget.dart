import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TransactionCardWidget extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onShare;
  final VoidCallback? onDispute;

  const TransactionCardWidget({
    Key? key,
    required this.transaction,
    this.onTap,
    this.onRetry,
    this.onShare,
    this.onDispute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isReceived = transaction['type'] == 'received';
    final String status = transaction['status'] ?? 'completed';
    final double amount = (transaction['amount'] as num).toDouble();

    return Dismissible(
      key: Key(transaction['id'].toString()),
      background: _buildSwipeBackground(context, isLeft: true),
      secondaryBackground: _buildSwipeBackground(context, isLeft: false),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onShare?.call();
        } else {
          _showContextMenu(context);
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                _buildProfilePicture(),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              transaction['name'] ?? 'Unknown',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildAmountText(amount, isReceived),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatDateTime(transaction['timestamp']),
                              style: AppTheme.lightTheme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusIndicator(status),
                        ],
                      ),
                      if (transaction['description'] != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          transaction['description'],
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.lightTheme.colorScheme.primaryContainer,
      ),
      child: transaction['profilePicture'] != null
          ? ClipOval(
              child: CustomImageWidget(
                imageUrl: transaction['profilePicture'],
                width: 12.w,
                height: 12.w,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Text(
                (transaction['name'] ?? 'U').substring(0, 1).toUpperCase(),
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildAmountText(double amount, bool isReceived) {
    return Text(
      '${isReceived ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
        color: isReceived
            ? AppTheme.lightTheme.colorScheme.tertiary
            : AppTheme.lightTheme.colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppTheme.lightTheme.colorScheme.tertiary;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.lightTheme.colorScheme.secondary;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = AppTheme.lightTheme.colorScheme.error;
        statusText = 'Failed';
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppTheme.lightTheme.colorScheme.onSurfaceVariant;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: statusIcon.codePoint.toString(),
            color: statusColor,
            size: 3.w,
          ),
          SizedBox(width: 1.w),
          Text(
            statusText,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    return Container(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      color: isLeft
          ? AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.2)
          : AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.2),
      child: CustomIconWidget(
        iconName: isLeft ? 'share' : 'more_vert',
        color: isLeft
            ? AppTheme.lightTheme.colorScheme.tertiary
            : AppTheme.lightTheme.colorScheme.secondary,
        size: 6.w,
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            _buildContextMenuItem(
              context,
              'View Details',
              Icons.visibility,
              onTap,
            ),
            if (transaction['status'] == 'failed')
              _buildContextMenuItem(
                context,
                'Retry Payment',
                Icons.refresh,
                onRetry,
              ),
            _buildContextMenuItem(
              context,
              'Share Receipt',
              Icons.share,
              onShare,
            ),
            _buildContextMenuItem(
              context,
              'Add to Favorites',
              Icons.favorite_border,
              () => Navigator.pop(context),
            ),
            _buildContextMenuItem(
              context,
              'Export Details',
              Icons.download,
              () => Navigator.pop(context),
            ),
            if (transaction['status'] != 'completed')
              _buildContextMenuItem(
                context,
                'Dispute Transaction',
                Icons.report_problem,
                onDispute,
                isDestructive: true,
              ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.codePoint.toString(),
        color: isDestructive
            ? AppTheme.lightTheme.colorScheme.error
            : AppTheme.lightTheme.colorScheme.onSurface,
        size: 5.w,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: isDestructive
              ? AppTheme.lightTheme.colorScheme.error
              : AppTheme.lightTheme.colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';

    DateTime dateTime;
    if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown time';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
