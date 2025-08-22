import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PinAuthWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onForgotPin;
  final VoidCallback onUsePassword;

  const PinAuthWidget({
    Key? key,
    required this.onSuccess,
    required this.onForgotPin,
    required this.onUsePassword,
  }) : super(key: key);

  @override
  State<PinAuthWidget> createState() => _PinAuthWidgetState();
}

class _PinAuthWidgetState extends State<PinAuthWidget>
    with TickerProviderStateMixin {
  String _enteredPin = '';
  bool _isLoading = false;
  int _failedAttempts = 0;
  final int _maxAttempts = 3;
  final String _correctPin = '1234'; // Mock PIN for demo

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _dotController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _dotAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _dotController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4 && !_isLoading) {
      setState(() {
        _enteredPin += number;
      });

      HapticFeedback.lightImpact();
      _dotController.forward().then((_) => _dotController.reverse());

      if (_enteredPin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty && !_isLoading) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _validatePin() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate PIN validation
    await Future.delayed(const Duration(milliseconds: 800));

    if (_enteredPin == _correctPin) {
      HapticFeedback.heavyImpact();
      widget.onSuccess();
    } else {
      _failedAttempts++;
      HapticFeedback.heavyImpact();

      _shakeController.forward().then((_) {
        _shakeController.reverse();
        setState(() {
          _enteredPin = '';
          _isLoading = false;
        });
      });

      if (_failedAttempts >= _maxAttempts) {
        _showMaxAttemptsReached();
      } else {
        _showIncorrectPinMessage();
      }
    }
  }

  void _showIncorrectPinMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Incorrect PIN. ${_maxAttempts - _failedAttempts} attempts remaining.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showMaxAttemptsReached() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Maximum attempts reached. Please use password or contact support.',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Widget _buildPinDot(int index) {
    bool isFilled = index < _enteredPin.length;

    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isFilled && index == _enteredPin.length - 1
              ? _dotAnimation.value
              : 1.0,
          child: Container(
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline,
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 18.w,
        height: 18.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.lightTheme.colorScheme.surface,
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 2.h),

          // Title
          Text(
            'Enter PIN',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 1.h),

          // Subtitle with attempt counter
          Text(
            _failedAttempts > 0
                ? 'Incorrect PIN. ${_maxAttempts - _failedAttempts} attempts remaining.'
                : 'Enter your 4-digit PIN to continue',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: _failedAttempts > 0
                  ? AppTheme.lightTheme.colorScheme.error
                  : AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // PIN dots with shake animation
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.w),
                      child: _buildPinDot(index),
                    );
                  }),
                ),
              );
            },
          ),

          SizedBox(height: 4.h),

          // Loading indicator
          _isLoading
              ? SizedBox(
                  height: 6.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                )
              : SizedBox(height: 6.h),

          // Number pad
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  // Empty space
                  return const SizedBox();
                } else if (index == 10) {
                  // Zero button
                  return _buildNumberButton('0');
                } else if (index == 11) {
                  // Delete button
                  return GestureDetector(
                    onTap: _onDeletePressed,
                    child: Container(
                      width: 18.w,
                      height: 18.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.lightTheme.colorScheme.surface,
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'backspace',
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                          size: 6.w,
                        ),
                      ),
                    ),
                  );
                } else {
                  // Number buttons 1-9
                  return _buildNumberButton('${index + 1}');
                }
              },
            ),
          ),

          SizedBox(height: 2.h),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: widget.onForgotPin,
                child: Text(
                  'Forgot PIN?',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onUsePassword,
                child: Text(
                  'Use Password',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}