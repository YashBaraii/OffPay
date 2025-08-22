import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/camera_controls_widget.dart';
import './widgets/camera_overlay_widget.dart';
import './widgets/manual_input_dialog_widget.dart';

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({Key? key}) : super(key: key);

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isQrDetected = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Mock QR detection timer
  int _qrDetectionCounter = 0;

  // Mock payment data for demonstration
  final List<Map<String, dynamic>> _mockPaymentCodes = [
    {
      "code":
          "PAY_OFFLINE_eyJhbW91bnQiOiI1MC4wMCIsInNlbmRlciI6IkpvaG4gRG9lIiwicmVjZWl2ZXIiOiJKYW5lIFNtaXRoIiwidGltZXN0YW1wIjoiMjAyNS0wOC0yMlQxMToxMzo1OS4yNDg1NjNaIn0=",
      "amount": "\$50.00",
      "sender": "John Doe",
      "timestamp": "2025-08-22T11:13:59.248563Z",
      "description": "Lunch payment"
    },
    {
      "code":
          "PAY_OFFLINE_eyJhbW91bnQiOiIyNS41MCIsInNlbmRlciI6IkFsaWNlIEpvaG5zb24iLCJyZWNlaXZlciI6IkJvYiBTbWl0aCIsInRpbWVzdGFtcCI6IjIwMjUtMDgtMjJUMTE6MTM6NTkuMjQ4NTYzWiJ9",
      "amount": "\$25.50",
      "sender": "Alice Johnson",
      "timestamp": "2025-08-22T11:13:59.248563Z",
      "description": "Coffee payment"
    }
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      if (!await _requestCameraPermission()) {
        setState(() {
          _errorMessage = 'Camera permission is required to scan QR codes';
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available on this device';
        });
        return;
      }

      // Select appropriate camera
      final camera = kIsWeb
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first)
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first);

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      // Apply camera settings
      await _applyCameraSettings();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });

        // Start QR detection simulation
        _startQrDetectionSimulation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize camera. Please try again.';
        });
      }
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true; // Browser handles permissions

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _applyCameraSettings() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      if (!kIsWeb) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      // Ignore settings that are not supported
    }
  }

  void _startQrDetectionSimulation() {
    // Simulate QR code detection every 3 seconds for demo purposes
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _isCameraInitialized && !_isProcessing) {
        _qrDetectionCounter++;
        if (_qrDetectionCounter >= 2) {
          _simulateQrDetection();
        } else {
          _startQrDetectionSimulation();
        }
      }
    });
  }

  void _simulateQrDetection() {
    if (!mounted || _isProcessing) return;

    setState(() {
      _isQrDetected = true;
    });

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Process the detected QR code after a short delay
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        final mockPayment = _mockPaymentCodes[0];
        _processQrCode(mockPayment['code'] as String);
      }
    });
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Validate QR code format
      if (!_isValidPaymentCode(qrData)) {
        _showErrorDialog(
            'Invalid QR Code', 'This QR code is not a valid payment code.');
        return;
      }

      // Simulate processing delay
      await Future.delayed(Duration(milliseconds: 1000));

      // Extract payment data (in real app, this would decrypt the QR data)
      final paymentData = _extractPaymentData(qrData);

      if (paymentData != null) {
        // Navigate to payment confirmation screen
        Navigator.pushNamed(
          context,
          '/payment-confirmation-screen',
          arguments: paymentData,
        );
      } else {
        _showErrorDialog('Processing Error', 'Unable to process payment data.');
      }
    } catch (e) {
      _showErrorDialog(
          'Error', 'An error occurred while processing the QR code.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isQrDetected = false;
          _qrDetectionCounter = 0;
        });
        // Restart detection simulation
        _startQrDetectionSimulation();
      }
    }
  }

  bool _isValidPaymentCode(String code) {
    return code.contains('PAY_OFFLINE') ||
        code.contains('PAY') ||
        code.contains('{') ||
        code.startsWith('eyJ') ||
        code.length > 50;
  }

  Map<String, dynamic>? _extractPaymentData(String qrData) {
    // Find matching mock payment data
    for (final payment in _mockPaymentCodes) {
      if (payment['code'] == qrData) {
        return {
          'amount': payment['amount'],
          'sender': payment['sender'],
          'description': payment['description'],
          'timestamp': payment['timestamp'],
          'type': 'receive',
        };
      }
    }

    // If no exact match, return default data for demo
    return {
      'amount': '\$35.75',
      'sender': 'Michael Rodriguez',
      'description': 'Payment received',
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'receive',
    };
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || kIsWeb) return;

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      // Flash not supported, ignore
    }
  }

  Future<void> _focusCamera() async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.setFocusMode(FocusMode.auto);
      // Provide haptic feedback
      HapticFeedback.selectionClick();
    } catch (e) {
      // Focus not supported, ignore
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ManualInputDialogWidget(
          onCodeEntered: (String code) {
            _processQrCode(code);
          },
        );
      },
    );
  }

  void _handleBackPressed() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Receive Payment',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        leading: GestureDetector(
          onTap: _handleBackPressed,
          child: CustomIconWidget(
            iconName: 'arrow_back',
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (!_isCameraInitialized) {
      return _buildLoadingState();
    }

    return _buildCameraView();
  }

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'camera_alt',
            color: Colors.white.withValues(alpha: 0.6),
            size: 64,
          ),
          SizedBox(height: 4.h),
          Text(
            'Camera Unavailable',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            _errorMessage ?? 'Unable to access camera',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: _showManualInputDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.primaryColor,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            ),
            child: Text(
              'Enter Code Manually',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          TextButton(
            onPressed: _initializeCamera,
            child: Text(
              'Try Again',
              style: TextStyle(
                color: AppTheme.lightTheme.colorScheme.tertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.primaryColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Initializing Camera...',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera preview
        Container(
          width: double.infinity,
          height: double.infinity,
          child: CameraPreview(_cameraController!),
        ),

        // Camera overlay with scanning area
        CameraOverlayWidget(
          isQrDetected: _isQrDetected,
          onManualInputTap: _showManualInputDialog,
        ),

        // Camera controls
        CameraControlsWidget(
          isFlashOn: _isFlashOn,
          canToggleFlash: !kIsWeb,
          onFlashToggle: _toggleFlash,
          onFocusTap: _focusCamera,
          onBackPressed: _handleBackPressed,
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.tertiary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Processing Payment...',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
