import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/empty_state_widget.dart';
import './widgets/monthly_header_widget.dart';
import './widgets/search_filter_widget.dart';
import './widgets/transaction_card_widget.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({Key? key}) : super(key: key);

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  String _searchQuery = '';
  String _currentFilter = 'All';
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  Map<String, List<Map<String, dynamic>>> _groupedTransactions = {};
  Map<String, bool> _expandedMonths = {};

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadMockData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  void _loadMockData() {
    _allTransactions = [
      {
        "id": 1,
        "name": "Sarah Johnson",
        "amount": 125.50,
        "type": "received",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(hours: 2)),
        "description": "Coffee shop payment",
        "profilePicture":
            "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 2,
        "name": "Michael Chen",
        "amount": 75.00,
        "type": "sent",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(hours: 5)),
        "description": "Lunch split",
        "profilePicture":
            "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 3,
        "name": "Emma Wilson",
        "amount": 200.00,
        "type": "received",
        "status": "pending",
        "timestamp": DateTime.now().subtract(Duration(days: 1)),
        "description": "Freelance work payment",
        "profilePicture":
            "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 4,
        "name": "David Rodriguez",
        "amount": 50.25,
        "type": "sent",
        "status": "failed",
        "timestamp": DateTime.now().subtract(Duration(days: 2)),
        "description": "Gas money",
        "profilePicture":
            "https://images.pexels.com/photos/1681010/pexels-photo-1681010.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 5,
        "name": "Lisa Thompson",
        "amount": 300.00,
        "type": "received",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 3)),
        "description": "Rent contribution",
        "profilePicture":
            "https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 6,
        "name": "James Park",
        "amount": 89.99,
        "type": "sent",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 5)),
        "description": "Online purchase split",
        "profilePicture":
            "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 7,
        "name": "Anna Martinez",
        "amount": 150.00,
        "type": "received",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 7)),
        "description": "Birthday gift",
        "profilePicture":
            "https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 8,
        "name": "Robert Kim",
        "amount": 45.75,
        "type": "sent",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 10)),
        "description": "Movie tickets",
        "profilePicture":
            "https://images.pexels.com/photos/1212984/pexels-photo-1212984.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 9,
        "name": "Sophie Brown",
        "amount": 275.50,
        "type": "received",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 15)),
        "description": "Consulting fee",
        "profilePicture":
            "https://images.pexels.com/photos/1181686/pexels-photo-1181686.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 10,
        "name": "Alex Turner",
        "amount": 120.00,
        "type": "sent",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 20)),
        "description": "Gym membership",
        "profilePicture":
            "https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 11,
        "name": "Maria Garcia",
        "amount": 95.25,
        "type": "received",
        "status": "pending",
        "timestamp": DateTime.now().subtract(Duration(days: 25)),
        "description": "Grocery reimbursement",
        "profilePicture":
            "https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
      {
        "id": 12,
        "name": "Kevin Lee",
        "amount": 180.00,
        "type": "sent",
        "status": "completed",
        "timestamp": DateTime.now().subtract(Duration(days: 30)),
        "description": "Utility bill split",
        "profilePicture":
            "https://images.pexels.com/photos/1043471/pexels-photo-1043471.jpeg?auto=compress&cs=tinysrgb&w=400",
      },
    ];

    _applyFilters();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 1000));

    // In a real app, this would fetch more data from the server
    // For now, we'll just mark as no more data since we have all mock data
    setState(() {
      _isLoading = false;
      _hasMoreData = false;
    });
  }

  Future<void> _onRefresh() async {
    await Future.delayed(Duration(milliseconds: 1500));

    // In a real app, this would sync with the server
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });

    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _currentFilter = filter;
    });
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allTransactions);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((transaction) {
        final name = (transaction['name'] as String).toLowerCase();
        final amount = transaction['amount'].toString();
        final description =
            (transaction['description'] as String? ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            amount.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // Apply type filter
    if (_currentFilter != 'All') {
      filtered = filtered.where((transaction) {
        switch (_currentFilter) {
          case 'Sent':
            return transaction['type'] == 'sent';
          case 'Received':
            return transaction['type'] == 'received';
          case 'Pending':
            return transaction['status'] == 'pending';
          default:
            return true;
        }
      }).toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) {
      final aTime = a['timestamp'] as DateTime;
      final bTime = b['timestamp'] as DateTime;
      return bTime.compareTo(aTime);
    });

    setState(() {
      _filteredTransactions = filtered;
      _groupTransactionsByMonth();
    });
  }

  void _groupTransactionsByMonth() {
    _groupedTransactions.clear();

    for (var transaction in _filteredTransactions) {
      final timestamp = transaction['timestamp'] as DateTime;
      final monthYear = '${_getMonthName(timestamp.month)} ${timestamp.year}';

      if (!_groupedTransactions.containsKey(monthYear)) {
        _groupedTransactions[monthYear] = [];
        _expandedMonths[monthYear] = true; // Expand by default
      }

      _groupedTransactions[monthYear]!.add(transaction);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  double _calculateMonthlyTotal(List<Map<String, dynamic>> transactions) {
    double total = 0;
    for (var transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      if (transaction['type'] == 'received') {
        total += amount;
      } else {
        total -= amount;
      }
    }
    return total;
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildTransactionDetails(
          transaction,
          scrollController,
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(
    Map<String, dynamic> transaction,
    ScrollController scrollController,
  ) {
    final bool isReceived = transaction['type'] == 'received';
    final double amount = (transaction['amount'] as num).toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 20.w,
                    height: 20.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                    ),
                    child: transaction['profilePicture'] != null
                        ? ClipOval(
                            child: CustomImageWidget(
                              imageUrl: transaction['profilePicture'],
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Text(
                              (transaction['name'] ?? 'U')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: AppTheme
                                  .lightTheme.textTheme.headlineMedium
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 2.h),
                Center(
                  child: Text(
                    '${isReceived ? '+' : '-'}\$${amount.toStringAsFixed(2)}',
                    style:
                        AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                      color: isReceived
                          ? AppTheme.lightTheme.colorScheme.tertiary
                          : AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Center(
                  child: Text(
                    '${isReceived ? 'Received from' : 'Sent to'} ${transaction['name']}',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                _buildDetailRow('Transaction ID',
                    '#${transaction['id'].toString().padLeft(8, '0')}'),
                _buildDetailRow('Status', transaction['status']),
                _buildDetailRow('Date & Time',
                    _formatFullDateTime(transaction['timestamp'])),
                _buildDetailRow('Description',
                    transaction['description'] ?? 'No description'),
                _buildDetailRow('Payment Method', 'OfflinePay QR'),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'share',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 4.w,
                        ),
                        label: Text('Share Receipt'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'download',
                          color: AppTheme.lightTheme.colorScheme.onPrimary,
                          size: 4.w,
                        ),
                        label: Text('Download'),
                      ),
                    ),
                  ],
                ),
              ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDateTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$month $day, $year at $displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Transaction History'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Export functionality
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export feature coming soon!')),
              );
            },
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SearchFilterWidget(
            onSearchChanged: _onSearchChanged,
            onFilterChanged: _onFilterChanged,
            currentFilter: _currentFilter,
          ),
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: CustomIconWidget(
            iconName: 'keyboard_arrow_up',
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            size: 6.w,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty && _searchQuery.isEmpty) {
      return EmptyStateWidget(
        type: 'no_transactions',
        onAction: () => Navigator.pushNamed(context, '/send-payment'),
      );
    }

    if (_filteredTransactions.isEmpty && _searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        type: 'no_search_results',
        onAction: () {
          setState(() {
            _searchQuery = '';
          });
          _applyFilters();
        },
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(bottom: 10.h),
        itemCount: _buildItemCount(),
        itemBuilder: (context, index) => _buildListItem(index),
      ),
    );
  }

  int _buildItemCount() {
    int count = 0;
    for (var monthYear in _groupedTransactions.keys) {
      count++; // Header
      if (_expandedMonths[monthYear] == true) {
        count += _groupedTransactions[monthYear]!.length;
      }
    }
    if (_isLoading) count++;
    return count;
  }

  Widget _buildListItem(int index) {
    int currentIndex = 0;

    for (var monthYear in _groupedTransactions.keys) {
      if (currentIndex == index) {
        // Monthly header
        final transactions = _groupedTransactions[monthYear]!;
        final totalAmount = _calculateMonthlyTotal(transactions);

        return MonthlyHeaderWidget(
          monthYear: monthYear,
          transactionCount: transactions.length,
          totalAmount: totalAmount,
          isExpanded: _expandedMonths[monthYear] ?? true,
          onToggle: () {
            setState(() {
              _expandedMonths[monthYear] =
                  !(_expandedMonths[monthYear] ?? true);
            });
          },
        );
      }
      currentIndex++;

      if (_expandedMonths[monthYear] == true) {
        final transactions = _groupedTransactions[monthYear]!;
        if (index < currentIndex + transactions.length) {
          // Transaction card
          final transactionIndex = index - currentIndex;
          final transaction = transactions[transactionIndex];

          return TransactionCardWidget(
            transaction: transaction,
            onTap: () => _showTransactionDetails(transaction),
            onRetry: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Retrying transaction...')),
              );
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing receipt...')),
              );
            },
            onDispute: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dispute submitted')),
              );
            },
          );
        }
        currentIndex += transactions.length;
      }
    }

    // Loading indicator
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 4, // History tab is active
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/wallet-dashboard');
            break;
          case 1:
            Navigator.pushNamed(context, '/qr-code-scanner');
            break;
          case 2:
            Navigator.pushNamed(context, '/send-payment');
            break;
          case 3:
            Navigator.pushNamed(context, '/receive-payment');
            break;
          case 4:
            // Already on history page
            break;
          case 5:
            Navigator.pushNamed(context, '/profile-settings');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'qr_code_scanner',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'qr_code_scanner',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'Scan',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'send',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'send',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'Send',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'call_received',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'call_received',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'Receive',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'history',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'history',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 5.w,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 5.w,
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
