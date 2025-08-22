import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class CameraOverlayWidget extends StatelessWidget {
  final bool isQrDetected;
  final VoidCallback? onManualInputTap;

  const CameraOverlayWidget({
    Key? key,
    required this.isQrDetected,
    this.onManualInputTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Semi-transparent overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.6),
          ),

          // Scanning area cutout
          Center(
            child: Container(
              width: 70.w,
              height: 70.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isQrDetected
                      ? AppTheme.lightTheme.colorScheme.tertiary
                      : Colors.white,
                  width: 3.0,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Stack(
                children: [
                  // Corner guides
                  ...List.generate(4, (index) => _buildCornerGuide(index)),

                  // QR detection animation
                  if (isQrDetected)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.tertiary
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(13.0),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme.tertiary,
                          size: 48,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Instructions text
          Positioned(
            top: 20.h,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Column(
                children: [
                  Text(
                    'Point camera at QR code to receive payment',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Align the QR code within the frame',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Manual input button
          Positioned(
            bottom: 15.h,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onManualInputTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25.0),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: 'keyboard',
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Enter code manually',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerGuide(int index) {
    final positions = [
      {'top': 0.0, 'left': 0.0}, // Top-left
      {'top': 0.0, 'right': 0.0}, // Top-right
      {'bottom': 0.0, 'left': 0.0}, // Bottom-left
      {'bottom': 0.0, 'right': 0.0}, // Bottom-right
    ];

    final position = positions[index];

    return Positioned(
      top: position['top'],
      left: position['left'],
      right: position['right'],
      bottom: position['bottom'],
      child: Container(
        width: 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          border: Border(
            top: index < 2
                ? BorderSide(color: Colors.white, width: 4.0)
                : BorderSide.none,
            left: index % 2 == 0
                ? BorderSide(color: Colors.white, width: 4.0)
                : BorderSide.none,
            right: index % 2 == 1
                ? BorderSide(color: Colors.white, width: 4.0)
                : BorderSide.none,
            bottom: index >= 2
                ? BorderSide(color: Colors.white, width: 4.0)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
