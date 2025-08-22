import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import './widgets/biometric_auth_widget.dart';
import './widgets/password_auth_widget.dart';
import './widgets/pin_auth_widget.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen>
    with TickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _logoController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    // Simulate checking biometric availability
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, you would check if biometrics are available
    // For demo purposes, we assume they are available
  }

  void _navigateToPage(int page) {
    setState(() {
      _currentPage = page;
    });
    _slideController.forward().then((_) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _slideController.reverse();
    });
  }

  Future<void> _authenticateWithSupabase() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await AuthService.instance.signIn(
        email: 'john.doe@example.com', // Demo credentials
        password: 'password123',
      );

      if (response.user != null) {
        await _onAuthenticationSuccess();
      } else {
        _showError('Authentication failed. Please try again.');
      }
    } catch (error) {
      _showError('Authentication failed: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _onAuthenticationSuccess() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate authentication processing
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      HapticFeedback.heavyImpact();
      Navigator.pushReplacementNamed(context, '/dashboard-screen');
    }
  }

  void _onForgotPin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'PIN reset instructions sent to your registered email',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.lightTheme.colorScheme.primary,
                  AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'account_balance_wallet',
                    color: Colors.white,
                    size: 8.w,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'OP',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityIndicators() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'security',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Bank-level Security',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 3.w),
          CustomIconWidget(
            iconName: 'verified',
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'SSL Encrypted',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'wifi_off',
            color: AppTheme.lightTheme.colorScheme.tertiary,
            size: 3.5.w,
          ),
          SizedBox(width: 1.5.w),
          Text(
            'Offline Mode Available',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              fontWeight: FontWeight.w500,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with logo and security indicators
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  SizedBox(height: 2.h),

                  // App logo
                  _buildAppLogo(),

                  SizedBox(height: 2.h),

                  // App name
                  Text(
                    'OfflinePay',
                    style:
                        AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),

                  SizedBox(height: 0.5.h),

                  // Tagline
                  Text(
                    'Secure payments, anywhere',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Security indicators
                  _buildSecurityIndicators(),

                  SizedBox(height: 1.h),

                  // Offline indicator
                  _buildOfflineIndicator(),
                ],
              ),
            ),

            // Authentication content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Biometric authentication
                    BiometricAuthWidget(
                      onSuccess: _onAuthenticationSuccess,
                      onFallbackToPIN: () => _navigateToPage(1),
                    ),

                    // PIN authentication
                    PinAuthWidget(
                      onSuccess: _onAuthenticationSuccess,
                      onForgotPin: _onForgotPin,
                      onUsePassword: () => _navigateToPage(2),
                    ),

                    // Password authentication
                    PasswordAuthWidget(
                      onSuccess: _onAuthenticationSuccess,
                      onBackToPIN: () => _navigateToPage(1),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        width: _currentPage == index ? 8.w : 2.w,
                        height: 1.h,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: 2.h),

                  // Terms and privacy
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Add authentication button
            Container(
              margin: EdgeInsets.all(5.w),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticateWithSupabase,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Sign In with Demo Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 6.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
