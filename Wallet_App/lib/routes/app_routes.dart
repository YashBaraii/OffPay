import 'package:flutter/material.dart';
import '../presentation/send_payment/send_payment.dart';
import '../presentation/wallet_dashboard/wallet_dashboard.dart';
import '../presentation/receive_payment/receive_payment.dart';
import '../presentation/transaction_history/transaction_history.dart';
import '../presentation/profile_settings/profile_settings.dart';
import '../presentation/qr_code_scanner/qr_code_scanner.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String sendPayment = '/send-payment';
  static const String walletDashboard = '/wallet-dashboard';
  static const String receivePayment = '/receive-payment';
  static const String transactionHistory = '/transaction-history';
  static const String profileSettings = '/profile-settings';
  static const String qrCodeScanner = '/qr-code-scanner';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignUpScreen(),
    sendPayment: (context) => const SendPayment(),
    walletDashboard: (context) => const WalletDashboard(),
    receivePayment: (context) => const ReceivePayment(),
    transactionHistory: (context) => const TransactionHistory(),
    profileSettings: (context) => const ProfileSettings(),
    qrCodeScanner: (context) => const QrCodeScanner(),
    // TODO: Add your other routes here
  };
}
