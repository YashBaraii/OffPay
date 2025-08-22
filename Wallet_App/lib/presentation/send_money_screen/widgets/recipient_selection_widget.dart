import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecipientSelectionWidget extends StatefulWidget {
  final Function(String) onRecipientSelected;
  final String? selectedRecipient;

  const RecipientSelectionWidget({
    Key? key,
    required this.onRecipientSelected,
    this.selectedRecipient,
  }) : super(key: key);

  @override
  State<RecipientSelectionWidget> createState() =>
      _RecipientSelectionWidgetState();
}

class _RecipientSelectionWidgetState extends State<RecipientSelectionWidget> {
  final TextEditingController _recipientController = TextEditingController();
  final FocusNode _recipientFocusNode = FocusNode();

  // Mock recent recipients data
  final List<Map<String, dynamic>> recentRecipients = [
    {
      "id": "1",
      "name": "Sarah Johnson",
      "phone": "+1 (555) 123-4567",
      "email": "sarah.johnson@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face",
      "lastTransaction": "2025-08-20",
    },
    {
      "id": "2",
      "name": "Michael Chen",
      "phone": "+1 (555) 987-6543",
      "email": "michael.chen@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
      "lastTransaction": "2025-08-19",
    },
    {
      "id": "3",
      "name": "Emma Rodriguez",
      "phone": "+1 (555) 456-7890",
      "email": "emma.rodriguez@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
      "lastTransaction": "2025-08-18",
    },
    {
      "id": "4",
      "name": "David Kim",
      "phone": "+1 (555) 321-0987",
      "email": "david.kim@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
      "lastTransaction": "2025-08-17",
    },
    {
      "id": "5",
      "name": "Lisa Thompson",
      "phone": "+1 (555) 654-3210",
      "email": "lisa.thompson@email.com",
      "avatar":
          "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&h=150&fit=crop&crop=face",
      "lastTransaction": "2025-08-16",
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedRecipient != null) {
      _recipientController.text = widget.selectedRecipient!;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _recipientFocusNode.dispose();
    super.dispose();
  }

  void _selectRecentRecipient(Map<String, dynamic> recipient) {
    final recipientInfo = "${recipient['name']} (${recipient['phone']})";
    _recipientController.text = recipientInfo;
    widget.onRecipientSelected(recipientInfo);
    _recipientFocusNode.unfocus();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^\+?1?\d{10,14}$')
        .hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
  }

  void _onRecipientChanged(String value) {
    widget.onRecipientSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Manual recipient input
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _recipientFocusNode.hasFocus
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.outline,
              width: _recipientFocusNode.hasFocus ? 2.0 : 1.0,
            ),
          ),
          child: TextField(
            controller: _recipientController,
            focusNode: _recipientFocusNode,
            onChanged: _onRecipientChanged,
            decoration: InputDecoration(
              labelText: 'Phone or Email',
              hintText: 'Enter phone number or email address',
              prefixIcon: Padding(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'person',
                  color: _recipientFocusNode.hasFocus
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
              ),
              suffixIcon: _recipientController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _recipientController.clear();
                        widget.onRecipientSelected('');
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 5.w,
                      ),
                    )
                  : IconButton(
                      onPressed: () {
                        // Contact picker functionality would go here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Contact picker feature coming soon'),
                            backgroundColor:
                                AppTheme.lightTheme.colorScheme.secondary,
                          ),
                        );
                      },
                      icon: CustomIconWidget(
                        iconName: 'contacts',
                        color: AppTheme.lightTheme.primaryColor,
                        size: 5.w,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
        ),

        // Validation message
        if (_recipientController.text.isNotEmpty &&
            !_isValidEmail(_recipientController.text) &&
            !_isValidPhone(_recipientController.text))
          Padding(
            padding: EdgeInsets.only(top: 1.h, left: 4.w),
            child: Text(
              'Please enter a valid phone number or email address',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
              ),
            ),
          ),

        SizedBox(height: 3.h),

        // Recent recipients section
        Text(
          'Recent Recipients',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // Recent recipients horizontal list
        SizedBox(
          height: 12.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 1.w),
            itemCount: recentRecipients.length,
            separatorBuilder: (context, index) => SizedBox(width: 3.w),
            itemBuilder: (context, index) {
              final recipient = recentRecipients[index];
              final isSelected = _recipientController.text
                  .contains(recipient['name'] as String);

              return GestureDetector(
                onTap: () => _selectRecentRecipient(recipient),
                child: Container(
                  width: 18.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.primaryColor
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme.outline
                                    .withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: ClipOval(
                          child: CustomImageWidget(
                            imageUrl: recipient['avatar'] as String,
                            width: 12.w,
                            height: 12.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      SizedBox(height: 1.h),

                      // Name
                      Text(
                        (recipient['name'] as String).split(' ').first,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.lightTheme.primaryColor
                              : AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
