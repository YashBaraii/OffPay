import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ManualInputDialogWidget extends StatefulWidget {
  final Function(String) onCodeEntered;

  const ManualInputDialogWidget({
    Key? key,
    required this.onCodeEntered,
  }) : super(key: key);

  @override
  State<ManualInputDialogWidget> createState() =>
      _ManualInputDialogWidgetState();
}

class _ManualInputDialogWidgetState extends State<ManualInputDialogWidget> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'qr_code',
                  color: AppTheme.lightTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Enter QR Code',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),

            // Instructions
            Text(
              'Manually enter the payment QR code data if camera scanning is not available.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),

            SizedBox(height: 3.h),

            // Input field
            TextField(
              controller: _codeController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'QR Code Data',
                hintText: 'Paste or type the QR code content here...',
                errorText: _errorMessage,
                suffixIcon: _codeController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _codeController.clear();
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                        child: CustomIconWidget(
                          iconName: 'clear',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
              inputFormatters: [
                LengthLimitingTextInputFormatter(500),
              ],
            ),

            SizedBox(height: 2.h),

            // Paste from clipboard button
            GestureDetector(
              onTap: _pasteFromClipboard,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color:
                      AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color:
                        AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'content_paste',
                      color: AppTheme.lightTheme.primaryColor,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Paste from clipboard',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 4.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValidating ? null : _validateAndSubmit,
                    child: _isValidating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Process'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        _codeController.text = data.text!;
        setState(() {
          _errorMessage = null;
        });
      }
    } catch (e) {
      // Handle clipboard access error silently
    }
  }

  Future<void> _validateAndSubmit() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter QR code data';
      });
      return;
    }

    if (code.length < 10) {
      setState(() {
        _errorMessage = 'QR code data seems too short';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    // Simulate validation delay
    await Future.delayed(Duration(milliseconds: 500));

    // Basic validation for payment QR code format
    if (!_isValidPaymentCode(code)) {
      setState(() {
        _isValidating = false;
        _errorMessage = 'Invalid payment QR code format';
      });
      return;
    }

    setState(() {
      _isValidating = false;
    });

    // Close dialog and return the code
    Navigator.of(context).pop();
    widget.onCodeEntered(code);
  }

  bool _isValidPaymentCode(String code) {
    // Basic validation for payment QR codes
    // In a real app, this would validate against the actual encryption format
    return code.contains('PAY') ||
        code.contains('OFFLINE') ||
        code.contains('{') ||
        code.startsWith('eyJ') || // Base64 encoded JSON
        code.length > 50; // Minimum length for encrypted payment data
  }
}
