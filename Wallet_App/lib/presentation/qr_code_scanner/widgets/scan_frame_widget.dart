import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ScanFrameWidget extends StatefulWidget {
  final bool isScanning;
  final String? scanResult;

  const ScanFrameWidget({
    super.key,
    required this.isScanning,
    this.scanResult,
  });

  @override
  State<ScanFrameWidget> createState() => _ScanFrameWidgetState();
}

class _ScanFrameWidgetState extends State<ScanFrameWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isScanning) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ScanFrameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _animationController.repeat();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 60.w,
        height: 60.w,
        child: Stack(
          children: [
            // Corner frames
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(
                topLeft: true,
                color: widget.scanResult != null
                    ? _getResultColor()
                    : AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(
                topRight: true,
                color: widget.scanResult != null
                    ? _getResultColor()
                    : AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(
                bottomLeft: true,
                color: widget.scanResult != null
                    ? _getResultColor()
                    : AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(
                bottomRight: true,
                color: widget.scanResult != null
                    ? _getResultColor()
                    : AppTheme.lightTheme.colorScheme.primary,
              ),
            ),

            // Scanning line animation
            if (widget.isScanning && widget.scanResult == null)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Positioned(
                    top: _animation.value * (60.w - 4),
                    left: 4,
                    right: 4,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.lightTheme.colorScheme.primary,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Result indicator
            if (widget.scanResult != null)
              Center(
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: _getResultColor(),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: CustomIconWidget(
                    iconName: _getResultIcon(),
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    required Color color,
  }) {
    return Container(
      width: 8.w,
      height: 8.w,
      child: CustomPaint(
        painter: CornerPainter(
          color: color,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Color _getResultColor() {
    if (widget.scanResult == null)
      return AppTheme.lightTheme.colorScheme.primary;

    if (widget.scanResult!.contains('valid')) {
      return AppTheme.lightTheme.colorScheme.tertiary;
    } else if (widget.scanResult!.contains('invalid') ||
        widget.scanResult!.contains('expired')) {
      return AppTheme.lightTheme.colorScheme.error;
    } else if (widget.scanResult!.contains('duplicate')) {
      return AppTheme.lightTheme.colorScheme.secondary;
    }
    return AppTheme.lightTheme.colorScheme.primary;
  }

  String _getResultIcon() {
    if (widget.scanResult == null) return 'qr_code_scanner';

    if (widget.scanResult!.contains('valid')) {
      return 'check_circle';
    } else if (widget.scanResult!.contains('invalid') ||
        widget.scanResult!.contains('expired')) {
      return 'error';
    } else if (widget.scanResult!.contains('duplicate')) {
      return 'warning';
    }
    return 'qr_code_scanner';
  }
}

class CornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  CornerPainter({
    required this.color,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cornerLength = size.width * 0.6;

    if (topLeft) {
      canvas.drawLine(Offset(0, cornerLength), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    }

    if (topRight) {
      canvas.drawLine(
          Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
      canvas.drawLine(
          Offset(size.width, 0), Offset(size.width, cornerLength), paint);
    }

    if (bottomLeft) {
      canvas.drawLine(
          Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
      canvas.drawLine(
          Offset(0, size.height), Offset(cornerLength, size.height), paint);
    }

    if (bottomRight) {
      canvas.drawLine(Offset(size.width - cornerLength, size.height),
          Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height),
          Offset(size.width, size.height - cornerLength), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
