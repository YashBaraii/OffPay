import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';

class PinInputDialog extends StatefulWidget {
  final Function(String) onPinEntered;
  final VoidCallback onCancel;

  const PinInputDialog({
    Key? key,
    required this.onPinEntered,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String _pin = '';
  bool _isError = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(String value, int index) {
    setState(() {
      _isError = false;
    });

    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    _pin = _controllers.map((controller) => controller.text).join();

    if (_pin.length == 4) {
      widget.onPinEntered(_pin);
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  void _showError() {
    setState(() {
      _isError = true;
    });

    // Clear all fields
    for (var controller in _controllers) {
      controller.clear();
    }
    _pin = '';
    _focusNodes[0].requestFocus();

    // Vibrate on error
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.w),
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'lock',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Enter PIN',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancel,
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 6.w,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // Instruction text
            Text(
              'Please enter your 4-digit PIN to confirm this payment',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 4.h),

            // PIN Input Fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isError
                          ? AppTheme.lightTheme.colorScheme.error
                          : _controllers[index].text.isNotEmpty
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline,
                      width: _isError || _controllers[index].text.isNotEmpty
                          ? 2
                          : 1,
                    ),
                    borderRadius: BorderRadius.circular(3.w),
                    color: _isError
                        ? AppTheme.lightTheme.colorScheme.error
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: true,
                    style:
                        AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onPinChanged(value, index),
                    onTap: () {
                      _controllers[index].selection =
                          TextSelection.fromPosition(
                        TextPosition(offset: _controllers[index].text.length),
                      );
                    },
                    onSubmitted: (value) {
                      if (value.isEmpty && index > 0) {
                        _onBackspace(index);
                      }
                    },
                  ),
                );
              }),
            ),

            if (_isError) ...[
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'error',
                    color: AppTheme.lightTheme.colorScheme.error,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Incorrect PIN. Please try again.',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: 4.h),

            // Biometric option
            TextButton.icon(
              onPressed: () {
                // Biometric authentication would be triggered here
                Navigator.of(context).pop();
                // Simulate biometric success for demo
                Future.delayed(Duration(milliseconds: 500), () {
                  widget.onPinEntered('biometric');
                });
              },
              icon: CustomIconWidget(
                iconName: 'fingerprint',
                color: AppTheme.lightTheme.colorScheme.tertiary,
                size: 5.w,
              ),
              label: Text(
                'Use Biometric Authentication',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.tertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to be called from parent when PIN verification fails
  void showError() {
    _showError();
  }
}
