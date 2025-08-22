import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({Key? key}) : super(key: key);

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  int _currentIndex = 4; // Profile tab active
  bool _biometricEnabled = true;
  bool _notificationsEnabled = true;
  bool _offlineModeEnabled = false;

  // Mock user data
  final Map<String, dynamic> _userData = {
    "profileImage":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
    "name": "John Anderson",
    "phone": "+1 (555) 123-4567",
    "email": "john.anderson@email.com",
    "lastLogin": "2025-08-22 09:45:12",
    "appVersion": "1.2.3",
    "buildNumber": "45"
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            onPressed: _showAppInfo,
            icon: CustomIconWidget(
              iconName: 'info_outline',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2.h),
            ProfileHeaderWidget(
              profileImageUrl: _userData["profileImage"] as String,
              userName: _userData["name"] as String,
              phoneNumber: _userData["phone"] as String,
              email: _userData["email"] as String,
              onEditProfile: _editProfile,
              onChangeProfilePicture: _changeProfilePicture,
            ),
            SizedBox(height: 3.h),
            SettingsSectionWidget(
              title: 'Account Settings',
              items: [
                SettingsItemData(
                  iconName: 'person',
                  title: 'Personal Information',
                  subtitle: 'Update your name, phone, and email',
                  onTap: _editPersonalInfo,
                ),
                SettingsItemData(
                  iconName: 'account_balance',
                  title: 'Linked Accounts',
                  subtitle: 'Manage connected bank accounts',
                  onTap: _manageLinkedAccounts,
                ),
                SettingsItemData(
                  iconName: 'backup',
                  title: 'Backup & Restore',
                  subtitle: 'Secure cloud backup of your data',
                  onTap: _backupRestore,
                ),
              ],
            ),
            SettingsSectionWidget(
              title: 'Security Settings',
              items: [
                SettingsItemData(
                  iconName: 'lock',
                  title: 'Change PIN',
                  subtitle: 'Update your security PIN',
                  onTap: _changePIN,
                ),
                SettingsItemData(
                  iconName: 'fingerprint',
                  title: 'Biometric Authentication',
                  subtitle: _biometricEnabled ? 'Enabled' : 'Disabled',
                  hasSwitch: true,
                  switchValue: _biometricEnabled,
                  onSwitchChanged: _toggleBiometric,
                  showDisclosure: false,
                ),
                SettingsItemData(
                  iconName: 'account_balance_wallet',
                  title: 'Transaction Limits',
                  subtitle: 'Set daily and monthly limits',
                  onTap: _setTransactionLimits,
                ),
              ],
            ),
            SettingsSectionWidget(
              title: 'App Preferences',
              items: [
                SettingsItemData(
                  iconName: 'notifications',
                  title: 'Notifications',
                  subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                  hasSwitch: true,
                  switchValue: _notificationsEnabled,
                  onSwitchChanged: _toggleNotifications,
                  showDisclosure: false,
                ),
                SettingsItemData(
                  iconName: 'wifi_off',
                  title: 'Offline Mode',
                  subtitle: _offlineModeEnabled ? 'Enabled' : 'Disabled',
                  hasSwitch: true,
                  switchValue: _offlineModeEnabled,
                  onSwitchChanged: _toggleOfflineMode,
                  showDisclosure: false,
                ),
                SettingsItemData(
                  iconName: 'attach_money',
                  title: 'Currency Display',
                  subtitle: 'USD (\$)',
                  onTap: _changeCurrency,
                ),
              ],
            ),
            SettingsSectionWidget(
              title: 'Support & Help',
              items: [
                SettingsItemData(
                  iconName: 'help_center',
                  title: 'Help Center',
                  subtitle: 'FAQs and troubleshooting',
                  onTap: _openHelpCenter,
                ),
                SettingsItemData(
                  iconName: 'support_agent',
                  title: 'Contact Support',
                  subtitle: '24/7 customer support',
                  onTap: _contactSupport,
                ),
                SettingsItemData(
                  iconName: 'rate_review',
                  title: 'Rate App',
                  subtitle: 'Share your feedback',
                  onTap: _rateApp,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            LogoutButtonWidget(
              onLogout: _logout,
            ),
            SizedBox(height: 10.h), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.lightTheme.primaryColor,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: _currentIndex == 0
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'qr_code_scanner',
              color: _currentIndex == 1
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'send',
              color: _currentIndex == 2
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'history',
              color: _currentIndex == 3
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 4
                  ? AppTheme.lightTheme.primaryColor
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 6.w,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/wallet-dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/qr-code-scanner');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/send-payment');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/transaction-history');
        break;
      case 4:
        // Already on profile settings
        break;
    }
  }

  void _editProfile() {
    _showSnackBar('Edit Profile feature will be available soon');
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 1.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.dividerColor,
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Change Profile Picture',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  'camera',
                  'Take Photo',
                  () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildPhotoOption(
                  'photo_library',
                  'Choose from Gallery',
                  () {
                    Navigator.pop(context);
                    _chooseFromGallery();
                  },
                ),
                _buildPhotoOption(
                  'delete',
                  'Remove Picture',
                  () {
                    Navigator.pop(context);
                    _removePicture();
                  },
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(String iconName, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3.w),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: AppTheme.lightTheme.primaryColor,
                size: 7.w,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _takePhoto() {
    _showSnackBar('Camera feature will be available soon');
  }

  void _chooseFromGallery() {
    _showSnackBar('Gallery selection will be available soon');
  }

  void _removePicture() {
    _showSnackBar('Profile picture removed');
  }

  void _editPersonalInfo() {
    _showSnackBar('Personal information editing will be available soon');
  }

  void _manageLinkedAccounts() {
    _showSnackBar('Linked accounts management will be available soon');
  }

  void _backupRestore() {
    _showSnackBar('Backup & restore feature will be available soon');
  }

  void _changePIN() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        title: Text(
          'Change PIN',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'To change your PIN, you need to verify your current PIN first. This feature will be available soon.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleBiometric(bool value) {
    setState(() {
      _biometricEnabled = value;
    });
    HapticFeedback.lightImpact();
    _showSnackBar(_biometricEnabled
        ? 'Biometric authentication enabled'
        : 'Biometric authentication disabled');
  }

  void _setTransactionLimits() {
    _showSnackBar('Transaction limits configuration will be available soon');
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
    HapticFeedback.lightImpact();
    _showSnackBar(_notificationsEnabled
        ? 'Notifications enabled'
        : 'Notifications disabled');
  }

  void _toggleOfflineMode(bool value) {
    setState(() {
      _offlineModeEnabled = value;
    });
    HapticFeedback.lightImpact();
    _showSnackBar(
        _offlineModeEnabled ? 'Offline mode enabled' : 'Offline mode disabled');
  }

  void _changeCurrency() {
    _showSnackBar('Currency selection will be available soon');
  }

  void _openHelpCenter() {
    _showSnackBar('Help center will be available soon');
  }

  void _contactSupport() {
    _showSnackBar('Support contact will be available soon');
  }

  void _rateApp() {
    _showSnackBar('App rating will be available soon');
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3.w),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: AppTheme.lightTheme.primaryColor,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'App Information',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Version', _userData["appVersion"] as String),
            SizedBox(height: 1.h),
            _buildInfoRow('Build', _userData["buildNumber"] as String),
            SizedBox(height: 1.h),
            _buildInfoRow('Last Login', _userData["lastLogin"] as String),
            SizedBox(height: 2.h),
            Text(
              'OfflinePay P2P - Secure offline payments',
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _logout() {
    // Simulate logout process
    _showSnackBar('Logging out...');

    // In a real app, this would clear user data and navigate to login
    Future.delayed(const Duration(seconds: 1), () {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/wallet-dashboard',
        (route) => false,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
        margin: EdgeInsets.all(4.w),
      ),
    );
  }
}
