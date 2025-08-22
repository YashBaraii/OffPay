import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentNoteWidget extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;

  const PaymentNoteWidget({
    Key? key,
    required this.controller,
    this.maxLength = 100,
  }) : super(key: key);

  @override
  State<PaymentNoteWidget> createState() => _PaymentNoteWidgetState();
}

class _PaymentNoteWidgetState extends State<PaymentNoteWidget> {
  final FocusNode _focusNode = FocusNode();
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _currentLength = widget.controller.text.length;
    widget.controller.addListener(_updateLength);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLength);
    _focusNode.dispose();
    super.dispose();
  }

  void _updateLength() {
    setState(() {
      _currentLength = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Note (Optional)',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$_currentLength/${widget.maxLength}',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: _currentLength > widget.maxLength * 0.8
                    ? AppTheme.lightTheme.colorScheme.error
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(3.w),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLines: 3,
            maxLength: widget.maxLength,
            textInputAction: TextInputAction.done,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'What\'s this payment for?',
              hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.all(4.w),
              counterText: '',
            ),
          ),
        ),
        SizedBox(height: 1.h),
        // Suggested notes
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            _buildSuggestedNote('Lunch'),
            _buildSuggestedNote('Coffee'),
            _buildSuggestedNote('Gas money'),
            _buildSuggestedNote('Groceries'),
            _buildSuggestedNote('Dinner'),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestedNote(String note) {
    return GestureDetector(
      onTap: () {
        if (widget.controller.text.isEmpty) {
          widget.controller.text = note;
        } else if (!widget.controller.text.contains(note)) {
          String currentText = widget.controller.text;
          String newText = currentText.isEmpty ? note : '$currentText, $note';
          if (newText.length <= widget.maxLength) {
            widget.controller.text = newText;
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primaryContainer
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(5.w),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 4.w,
            ),
            SizedBox(width: 1.w),
            Text(
              note,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
