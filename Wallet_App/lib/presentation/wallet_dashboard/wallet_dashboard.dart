import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/transaction.dart' as TransactionModel;
import '../../models/user_profile.dart';
import '../../models/wallet_account.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/action_buttons.dart';
import './widgets/bottom_navigation_bar.dart';
import './widgets/offline_indicator.dart';
import './widgets/recent_transactions_list.dart';
import './widgets/wallet_balance_card.dart';

class WalletDashboard extends StatefulWidget {
  const WalletDashboard({Key? key}) : super(key: key);

  @override
  State<WalletDashboard> createState() => _WalletDashboardState();
}

class _WalletDashboardState extends State<WalletDashboard> {
  bool _isBalanceVisible = true;
  bool _isOffline = false;
  int _currentNavIndex = 0;
  int _pendingTransactionCount = 0;
  double _walletBalance = 0.0;
  bool _isLoading = true;

  UserProfile? _userProfile;
  WalletAccount? _primaryWallet;
  List<TransactionModel.Transaction> _recentTransactions = [];

  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkConnectivity();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((authState) {
      if (authState.event == 'signedOut') {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (authState.event == 'signedIn') {
        _initializeData();
      }
    });
  }

  Future<void> _initializeData() async {
    if (!_authService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      _userProfile = await _authService.getCurrentUserProfile();

      // Load primary wallet
      _primaryWallet = await _walletService.getPrimaryWallet();

      if (_primaryWallet != null) {
        setState(() {
          _walletBalance = _primaryWallet!.balance;
        });

        // Load recent transactions
        _recentTransactions = await _transactionService.getUserTransactions(
          limit: 5,
        );

        // Calculate pending transactions
        _pendingTransactionCount =
            await _transactionService.getPendingTransactionsCount();
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Error loading wallet data: ${error.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isOffline = result == ConnectivityResult.none;
      });

      if (!_isOffline && _pendingTransactionCount > 0) {
        _syncPendingTransactions();
      }
    });
  }

  void _toggleBalanceVisibility() {
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  void _refreshTransactions() async {
    if (_isOffline) {
      Fluttertoast.showToast(
        msg: "Cannot sync while offline. Showing cached transactions.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    Fluttertoast.showToast(
      msg: "Syncing transactions...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    try {
      // Sync offline transactions
      await _transactionService.syncOfflineTransactions();

      // Refresh data
      await _initializeData();

      Fluttertoast.showToast(
        msg: "Transactions synced successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (error) {
      Fluttertoast.showToast(
        msg: "Sync failed: ${error.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _syncPendingTransactions() async {
    if (_pendingTransactionCount > 0) {
      Fluttertoast.showToast(
        msg:
            "Syncing $_pendingTransactionCount pending transaction${_pendingTransactionCount > 1 ? 's' : ''}...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      try {
        await _transactionService.syncOfflineTransactions();
        await _initializeData();

        Fluttertoast.showToast(
          msg: "All transactions synced successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Sync failed: ${error.toString()}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  void _onTransactionTap(dynamic transactionData) {
    final TransactionModel.Transaction transaction;
    if (transactionData is Map<String, dynamic>) {
      transaction = _recentTransactions.firstWhere(
        (t) => t.id == transactionData['id'],
        orElse: () => TransactionModel.Transaction(
          id: transactionData['id'] ?? '',
          transactionNumber: 'TXN000',
          amount: (transactionData['amount'] as double?) ?? 0.0,
          transactionType: transactionData['type'] ?? 'sent',
          transactionStatus: transactionData['status'] ?? 'pending',
          note: transactionData['note'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          senderName: transactionData['senderName'],
          receiverName: transactionData['receiverName'],
        ),
      );
    } else {
      transaction = transactionData as TransactionModel.Transaction;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsSheet(transaction),
    );
  }

  Widget _buildTransactionDetailsSheet(
      TransactionModel.Transaction transaction) {
    final bool isReceived = transaction.isReceived;
    final String status = transaction.transactionStatus;
    final Color statusColor = AppTheme.getStatusColor(status, isLight: true);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: isReceived
                  ? AppTheme.successLight.withValues(alpha: 0.1)
                  : AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomIconWidget(
              iconName: isReceived ? 'arrow_downward' : 'arrow_upward',
              color: isReceived
                  ? AppTheme.successLight
                  : AppTheme.lightTheme.primaryColor,
              size: 32,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            transaction.formattedAmount,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: isReceived
                      ? AppTheme.successLight
                      : AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          SizedBox(height: 3.h),
          _buildDetailRow('Transaction ID', transaction.transactionNumber),
          _buildDetailRow(
            isReceived ? 'From' : 'To',
            transaction.otherPartyName,
          ),
          _buildDetailRow('Amount', transaction.displayAmount),
          _buildDetailRow('Time', transaction.timestamp),
          if (transaction.note != null && transaction.note!.isNotEmpty)
            _buildDetailRow('Note', transaction.note!),
          SizedBox(height: 4.h),
          if (transaction.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _retryTransaction(transaction);
                },
                child: const Text('Retry Transaction'),
              ),
            ),
            SizedBox(height: 2.h),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _retryTransaction(TransactionModel.Transaction transaction) {
    if (_isOffline) {
      Fluttertoast.showToast(
        msg: "Cannot retry transaction while offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    Fluttertoast.showToast(
      msg: "Retrying transaction...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    _transactionService.retryTransaction(transaction.id).then((_) {
      Fluttertoast.showToast(
        msg: "Transaction retry initiated",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      _initializeData();
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "Retry failed: ${error.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    });
  }

  void _onSendMoney() {
    Navigator.pushNamed(context, '/send-payment');
  }

  void _onReceiveMoney() {
    Navigator.pushNamed(context, '/receive-payment');
  }

  void _onQRScan() {
    Navigator.pushNamed(context, '/qr-code-scanner');
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        // Already on wallet dashboard
        break;
      case 1:
        _onQRScan();
        break;
      case 2:
        Navigator.pushNamed(context, '/transaction-history');
        break;
      case 3:
        Navigator.pushNamed(context, '/profile-settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'account_balance_wallet',
              color: AppTheme.lightTheme.primaryColor,
              size: 24,
            ),
            SizedBox(width: 2.w),
            const Text('OfflinePay P2P'),
          ],
        ),
        actions: [
          if (_isOffline)
            Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'wifi_off',
                    color: AppTheme.warningLight,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'OFFLINE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.warningLight,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshTransactions(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              OfflineIndicator(
                isOffline: _isOffline,
                pendingTransactionCount: _pendingTransactionCount,
              ),
              WalletBalanceCard(
                balance: _walletBalance,
                isBalanceVisible: _isBalanceVisible,
                onToggleVisibility: _toggleBalanceVisibility,
              ),
              ActionButtons(
                onSendMoney: _onSendMoney,
                onReceiveMoney: _onReceiveMoney,
              ),
              SizedBox(height: 2.h),
              RecentTransactionsList(
                transactions: _recentTransactions
                    .map((t) => {
                          'id': t.id,
                          'type': t.transactionType,
                          'senderName': t.senderName ?? 'Unknown',
                          'receiverName': t.receiverName ?? 'Unknown',
                          'amount': t.amount,
                          'status': t.transactionStatus,
                          'timestamp': t.timestamp,
                          'date': t.createdAt.toIso8601String().split('T')[0],
                          'note': t.note,
                        })
                    .toList(),
                onRefresh: _refreshTransactions,
                onTransactionTap: _onTransactionTap,
              ),
              SizedBox(height: 10.h), // Space for bottom navigation
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onQRScan,
        child: CustomIconWidget(
          iconName: 'qr_code_scanner',
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}