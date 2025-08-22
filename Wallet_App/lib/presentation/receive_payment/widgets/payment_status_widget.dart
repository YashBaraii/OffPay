import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentStatusWidget extends StatelessWidget {
  final String status;
  final Map<String, dynamic>? senderDetails;
  final String? transactionId;

  const PaymentStatusWidget({
    Key? key,
    required this.status,
    this.senderDetails,
    this.transactionId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Status Icon and Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 8.w,
                ),
              ),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusTitle(),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _getStatusSubtitle(),
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Status-specific content
          if (status == 'processing' || status == 'waiting')
            _buildWaitingContent()
          else if (status == 'completed')
            _buildCompletedContent()
          else if (status == 'failed')
            _buildFailedContent(),
        ],
      ),
    );
  }

  Widget _buildWaitingContent() {
    return Column(
      children: [
        SizedBox(height: 3.h),
        // Animated dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 600 + (index * 200)),
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: 2.w,
              height: 2.w,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        SizedBox(height: 2.h),
        Text(
          status == 'waiting'
              ? 'Waiting for sender to scan QR code'
              : 'Processing payment...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletedContent() {
    return Column(
      children: [
        SizedBox(height: 3.h),
        // Success animation placeholder
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: _getStatusColor().withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'check',
              color: _getStatusColor(),
              size: 10.w,
            ),
          ),
        ),
        SizedBox(height: 3.h),

        // Sender Details
        if (senderDetails != null) ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Received From',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (senderDetails!['name'] as String).isNotEmpty
                              ? (senderDetails!['name'] as String)[0]
                                  .toUpperCase()
                              : 'S',
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderDetails!['name'] as String,
                            style: AppTheme.lightTheme.textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            senderDetails!['phoneNumber'] as String,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${senderDetails!['amount']}',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
        ],

        // Transaction ID
        if (transactionId != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'receipt',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Transaction ID: ',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    transactionId!,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFailedContent() {
    return Column(
      children: [
        SizedBox(height: 3.h),
        Text(
          'Payment could not be processed. Please try again.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        ElevatedButton.icon(
          onPressed: () {
            // Handle retry logic
          },
          icon: CustomIconWidget(
            iconName: 'refresh',
            color: Colors.white,
            size: 4.w,
          ),
          label: Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getStatusColor(),
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'processing':
      case 'waiting':
        return AppTheme.lightTheme.primaryColor;
      case 'failed':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'check_circle';
      case 'processing':
        return 'sync';
      case 'waiting':
        return 'schedule';
      case 'failed':
        return 'error';
      default:
        return 'info';
    }
  }

  String _getStatusTitle() {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Payment Received!';
      case 'processing':
        return 'Processing Payment';
      case 'waiting':
        return 'Waiting for Payment';
      case 'failed':
        return 'Payment Failed';
      default:
        return 'Unknown Status';
    }
  }

  String _getStatusSubtitle() {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Transaction completed successfully';
      case 'processing':
        return 'Please wait while we process';
      case 'waiting':
        return 'QR code is ready to scan';
      case 'failed':
        return 'Something went wrong';
      default:
        return '';
    }
  }
}
