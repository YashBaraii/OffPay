import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MemoInputWidget extends StatefulWidget {
  final Function(String) onMemoChanged;
  final String? initialMemo;

  const MemoInputWidget({
    Key? key,
    required this.onMemoChanged,
    this.initialMemo,
  }) : super(key: key);

  @override
  State<MemoInputWidget> createState() => _MemoInputWidgetState();
}

class _MemoInputWidgetState extends State<MemoInputWidget> {
  final TextEditingController _memoController = TextEditingController();
  final FocusNode _memoFocusNode = FocusNode();
  static const int maxCharacters = 100;

  @override
  void initState() {
    super.initState();
    if (widget.initialMemo != null) {
      _memoController.text = widget.initialMemo!;
    }
    _memoFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _memoController.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onMemoChanged(String value) {
    widget.onMemoChanged(value);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final characterCount = _memoController.text.length;
    final isNearLimit = characterCount > maxCharacters * 0.8;
    final isOverLimit = characterCount > maxCharacters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Text(
              'Add a Note',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '(Optional)',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Memo input field
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isOverLimit
                  ? AppTheme.lightTheme.colorScheme.error
                  : _memoFocusNode.hasFocus
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.outline,
              width: _memoFocusNode.hasFocus || isOverLimit ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              // Text input area
              TextField(
                controller: _memoController,
                focusNode: _memoFocusNode,
                onChanged: _onMemoChanged,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What\'s this payment for?',
                  hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(top: 3.w, left: 3.w, right: 2.w),
                    child: CustomIconWidget(
                      iconName: 'edit_note',
                      color: _memoFocusNode.hasFocus
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 5.w,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
              ),

              // Character counter and quick suggestions
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12.0),
                    bottomRight: Radius.circular(12.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Character counter
                    Text(
                      '$characterCount/$maxCharacters',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: isOverLimit
                            ? AppTheme.lightTheme.colorScheme.error
                            : isNearLimit
                                ? AppTheme.lightTheme.colorScheme.secondary
                                : AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isNearLimit ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),

                    const Spacer(),

                    // Clear button
                    if (_memoController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _memoController.clear();
                          widget.onMemoChanged('');
                        },
                        child: Container(
                          padding: EdgeInsets.all(1.w),
                          decoration: BoxDecoration(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: CustomIconWidget(
                            iconName: 'clear',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 4.w,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick memo suggestions
        if (_memoController.text.isEmpty && !_memoFocusNode.hasFocus) ...[
          SizedBox(height: 2.h),
          Text(
            'Quick suggestions:',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: [
              _buildSuggestionChip('Lunch'),
              _buildSuggestionChip('Coffee'),
              _buildSuggestionChip('Gas money'),
              _buildSuggestionChip('Dinner split'),
              _buildSuggestionChip('Movie tickets'),
              _buildSuggestionChip('Groceries'),
            ],
          ),
        ],

        // Error message for character limit
        if (isOverLimit) ...[
          SizedBox(height: 1.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              'Note is too long. Please keep it under $maxCharacters characters.',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return GestureDetector(
      onTap: () {
        _memoController.text = suggestion;
        widget.onMemoChanged(suggestion);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          suggestion,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
