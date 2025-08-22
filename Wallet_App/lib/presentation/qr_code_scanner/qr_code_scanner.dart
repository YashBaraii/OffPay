import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/bottom_controls_widget.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/manual_entry_dialog.dart';
import './widgets/scan_frame_widget.dart';

class QrCodeScanner extends StatefulWidget {
  const QrCodeScanner({super.key});

  @override
  State<QrCodeScanner> createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner>
    with WidgetsBindingObserver {
  MobileScannerController? _scannerController;
  bool _isInitialized = false;
  bool _isTorchOn = false;
  bool _isScanning = true;
  bool _showAmountInput = false;
  String? _scanResult;
  String? _scannedAmount;
  bool _hasPermission = false;

  // Mock user data
  final Map<String, dynamic> _userData = {
    "userId": "user_12345",
    "userName": "John Doe",
    "balance": 2450.75,
    "upiId": "john.doe@paytm",
    "phoneNumber": "+1234567890",
  };

  // Mock transaction data for validation
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      "id": "txn_001",
      "amount": 150.00,
      "timestamp": "2025-08-22T09:30:00Z",
      "status": "completed",
      "type": "sent",
      "recipient": "Alice Smith",
    },
    {
      "id": "txn_002",
      "amount": 75.50,
      "timestamp": "2025-08-22T08:15:00Z",
      "status": "pending",
      "type": "received",
      "sender": "Bob Johnson",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_scannerController == null || !_isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _initializeScanner();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _scannerController?.dispose();
        setState(() {
          _isInitialized = false;
        });
        break;
      default:
        break;
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (_hasPermission) {
      await _initializeScanner();
    }
  }

  Future<void> _initializeScanner() async {
    try {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      await _scannerController!.start();

      setState(() {
        _isInitialized = true;
        _isScanning = true;
      });
    } catch (e) {
      debugPrint('Error initializing scanner: $e');
      _showErrorDialog('Camera initialization failed. Please try again.');
    }
  }

  Future<void> _toggleTorch() async {
    if (_scannerController == null) return;

    try {
      await _scannerController!.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    _processQRCode(qrData);
  }

  void _processQRCode(String qrData) {
    setState(() {
      _isScanning = false;
    });

    HapticFeedback.mediumImpact();

    // Validate QR code format and extract payment information
    final validationResult = _validateQRCode(qrData);

    setState(() {
      _scanResult = validationResult['status'];
      _scannedAmount = validationResult['amount'];
      _showAmountInput = validationResult['status'] == 'valid';
    });

    if (validationResult['status'] == 'valid') {
      _showPaymentConfirmation(validationResult);
    } else {
      _showValidationError(validationResult['message']);
    }
  }

  Map<String, dynamic> _validateQRCode(String qrData) {
    // Mock QR validation logic
    if (qrData.length < 10) {
      return {
        'status': 'invalid',
        'message': 'Invalid QR code format',
        'amount': null,
      };
    }

    // Check for UPI format
    if (qrData.contains('upi://pay') ||
        qrData.contains('pa=') ||
        qrData.contains('pn=')) {
      // Extract amount if present
      final amountMatch = RegExp(r'am=(\d+\.?\d*)').firstMatch(qrData);
      final amount = amountMatch?.group(1);

      // Check for duplicate transaction (mock logic)
      final isDuplicate = _recentTransactions.any((txn) =>
          txn['amount'].toString() == amount &&
          DateTime.parse(txn['timestamp'])
              .isAfter(DateTime.now().subtract(Duration(minutes: 5))));

      if (isDuplicate) {
        return {
          'status': 'duplicate',
          'message': 'Duplicate transaction detected',
          'amount': amount,
        };
      }

      return {
        'status': 'valid',
        'message': 'Valid payment QR code',
        'amount': amount ?? '0.00',
        'recipientName': _extractRecipientName(qrData),
        'recipientUPI': _extractRecipientUPI(qrData),
      };
    }

    return {
      'status': 'invalid',
      'message': 'Unsupported QR code format',
      'amount': null,
    };
  }

  String _extractRecipientName(String qrData) {
    final nameMatch = RegExp(r'pn=([^&]+)').firstMatch(qrData);
    return nameMatch?.group(1)?.replaceAll('%20', ' ') ?? 'Unknown Recipient';
  }

  String _extractRecipientUPI(String qrData) {
    final upiMatch = RegExp(r'pa=([^&]+)').firstMatch(qrData);
    return upiMatch?.group(1) ?? 'unknown@upi';
  }

  void _showPaymentConfirmation(Map<String, dynamic> validationResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Payment Ready'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recipient: ${validationResult['recipientName']}'),
            Text('UPI ID: ${validationResult['recipientUPI']}'),
            if (validationResult['amount'] != null &&
                validationResult['amount'] != '0.00')
              Text('Amount: \$${validationResult['amount']}'),
            SizedBox(height: 2.h),
            Text(
              'Proceed to payment screen?',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _resetScanner,
            child: Text('Scan Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/send-payment');
            },
            child: Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Scan Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetScanner();
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _scanResult = null;
      _scannedAmount = null;
      _showAmountInput = false;
    });
  }

  void _onGenerateQR() {
    Navigator.pushNamed(context, '/receive-payment');
  }

  void _onAmountEntered(String amount) {
    setState(() {
      _scannedAmount = amount;
    });
  }

  void _onManualEntry() {
    showDialog(
      context: context,
      builder: (context) => ManualEntryDialog(
        onQRDataEntered: _processQRCode,
      ),
    );
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _hasPermission ? _buildScannerView() : _buildPermissionView(),
    );
  }

  Widget _buildPermissionView() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(6.w),
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'camera_alt',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Camera Permission Required',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'OfflinePay needs camera access to scan QR codes for payments. Your privacy is protected - we only process payment QR codes.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onClose,
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await openAppSettings();
                    },
                    child: Text('Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    if (!_isInitialized || _scannerController == null) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }

    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRCodeDetected,
        ),

        // Top overlay with controls
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: CameraOverlayWidget(
            onClose: _onClose,
            onToggleTorch: _toggleTorch,
            isTorchOn: _isTorchOn,
            balance: '\$${_userData['balance'].toStringAsFixed(2)}',
          ),
        ),

        // Scan frame in center
        ScanFrameWidget(
          isScanning: _isScanning,
          scanResult: _scanResult,
        ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BottomControlsWidget(
            onGenerateQR: _onGenerateQR,
            onAmountEntered: _onAmountEntered,
            showAmountInput: _showAmountInput,
            onManualEntry: _onManualEntry,
            scannedAmount: _scannedAmount,
          ),
        ),
      ],
    );
  }
}
