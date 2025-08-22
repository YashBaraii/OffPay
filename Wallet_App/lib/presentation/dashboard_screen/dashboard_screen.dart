import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import './widgets/balance_card_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/recent_transactions_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isBalanceVisible = true;
  bool _isOnline = true;
  double _currentBalance = 0.0;
  String _lastSyncTime = "Loading...";
  bool _isLoading = true;

  // Real transaction data from Supabase
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkConnectivity();
  }

  Future<void> _initializeData() async {
    try {
      await _loadUserBalance();
      await _loadRecentTransactions();
      _updateLastSyncTime();

      // Subscribe to real-time updates
      PaymentService.instance.subscribeToTransactions((transaction) {
        _loadRecentTransactions();
        _loadUserBalance();
      });
    } catch (e) {
      print('Error initializing data: $e');
      _showErrorSnackBar('Failed to load data. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserBalance() async {
    try {
      if (!AuthService.instance.isSignedIn) {
        _navigateToAuth();
        return;
      }

      final balance = await PaymentService.instance.getUserBalance();
      setState(() {
        _currentBalance = balance;
      });
    } catch (e) {
      print('Error loading balance: $e');
      setState(() {
        _currentBalance = 0.0;
      });
    }
  }

  Future<void> _loadRecentTransactions() async {
    try {
      if (!AuthService.instance.isSignedIn) return;

      final transactions =
          await PaymentService.instance.getRecentTransactions(limit: 10);
      final currentUserId = AuthService.instance.currentUser?.id;

      if (currentUserId != null) {
        final formattedTransactions = transactions.map((transaction) {
          return PaymentService.instance
              .formatTransactionForUI(transaction, currentUserId);
        }).toList();

        setState(() {
          _recentTransactions = formattedTransactions;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _recentTransactions = [];
      });
    }
  }

  void _checkConnectivity() {
    // Simulate connectivity check - in real app, use connectivity_plus package
    setState(() {
      _isOnline = DateTime.now().millisecond % 2 == 0;
    });
  }

  void _updateLastSyncTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    setState(() {
      _lastSyncTime = _isOnline
          ? "Just now"
          : "Today, $displayHour:${minute.toString().padLeft(2, '0')} $amPm";
    });
  }

  void _navigateToAuth() {
    // Navigate to authentication screen
    Navigator.pushNamed(context, '/authentication-screen');
  }

  void _toggleBalanceVisibility() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    _checkConnectivity();

    try {
      await _loadUserBalance();
      await _loadRecentTransactions();
      _updateLastSyncTime();
    } catch (e) {
      _showErrorSnackBar('Failed to refresh data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showTransactionContextMenu(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(0.25.h),
              ),
            ),
            SizedBox(height: 3.h),
            _buildContextMenuItem(
              icon: 'info',
              title: 'View Details',
              onTap: () {
                Navigator.pop(context);
                _showTransactionDetails(transaction);
              },
            ),
            _buildContextMenuItem(
              icon: 'share',
              title: 'Share Receipt',
              onTap: () {
                Navigator.pop(context);
                _shareReceipt(transaction);
              },
            ),
            _buildContextMenuItem(
              icon: 'report',
              title: 'Report Issue',
              onTap: () {
                Navigator.pop(context);
                _reportIssue(transaction);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: AppTheme.lightTheme.colorScheme.onSurface,
        size: 5.w,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
          fontSize: 16.sp,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.w),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${transaction['id']}'),
            SizedBox(height: 1.h),
            Text('Reference: ${transaction['reference_number'] ?? 'N/A'}'),
            SizedBox(height: 1.h),
            Text(
                'Amount: \$${(transaction['amount'] as double).toStringAsFixed(2)}'),
            SizedBox(height: 1.h),
            Text('Status: ${transaction['status']}'),
            SizedBox(height: 1.h),
            Text('Time: ${transaction['timestamp']}'),
            SizedBox(height: 1.h),
            Text('Description: ${transaction['description']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareReceipt(Map<String, dynamic> transaction) {
    // Implement sharing receipt
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt shared successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reportIssue(Map<String, dynamic> transaction) {
    // Implement reporting issue
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Issue reported. We will investigate shortly.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'OfflinePay',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 2.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _isOnline
                  ? AppTheme.successLight.withValues(alpha: 0.1)
                  : AppTheme.warningLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: _isOnline ? 'wifi' : 'wifi_off',
                  color:
                      _isOnline ? AppTheme.successLight : AppTheme.warningLight,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline
                        ? AppTheme.successLight
                        : AppTheme.warningLight,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BalanceCardWidget(
                balance: _currentBalance,
                lastSyncTime: _lastSyncTime,
                isOnline: _isOnline,
                onToggleVisibility: _toggleBalanceVisibility,
                isBalanceVisible: _isBalanceVisible,
              ),
              QuickActionsWidget(
                onSendMoney: () =>
                    Navigator.pushNamed(context, '/send-money-screen'),
                onRequestMoney: () =>
                    Navigator.pushNamed(context, '/receive-money-screen'),
                onScanQR: () =>
                    Navigator.pushNamed(context, '/qr-code-display-screen'),
              ),
              SizedBox(height: 2.h),
              RecentTransactionsWidget(
                transactions: _recentTransactions,
                onRefresh: _onRefresh,
                onTransactionTap: (transaction) =>
                    _showTransactionDetails(transaction),
                onTransactionDetails: (transaction) =>
                    _showTransactionDetails(transaction),
                onRepeatPayment: (transaction) {
                  Navigator.pushNamed(context, '/send-money-screen');
                },
                onTransactionLongPress: (transaction) =>
                    _showTransactionContextMenu(transaction),
              ),
              SizedBox(height: 10.h), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/send-money-screen'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4.0,
        icon: CustomIconWidget(
          iconName: 'send',
          color: Colors.white,
          size: 5.w,
        ),
        label: Text(
          'Send Money',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Navigate to different screens based on tab selection
          switch (index) {
            case 0:
              // Already on dashboard
              break;
            case 1:
              Navigator.pushNamed(context, '/send-money-screen');
              break;
            case 2:
              Navigator.pushNamed(context, '/receive-money-screen');
              break;
            case 3:
              // Navigate to history screen (not implemented)
              break;
            case 4:
              // Navigate to profile screen (not implemented)
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        selectedItemColor: AppTheme.lightTheme.colorScheme.primary,
        unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        elevation: 8.0,
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: _currentIndex == 0
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'send',
              color: _currentIndex == 1
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'qr_code',
              color: _currentIndex == 2
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            label: 'Receive',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'history',
              color: _currentIndex == 3
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'person',
              color: _currentIndex == 4
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
