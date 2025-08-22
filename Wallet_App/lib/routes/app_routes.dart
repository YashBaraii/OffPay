import 'package:flutter/material.dart';

import '../presentation/authentication_screen/authentication_screen.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/payment_confirmation_screen/payment_confirmation_screen.dart';
import '../presentation/qr_code_display_screen/qr_code_display_screen.dart';
import '../presentation/receive_money_screen/receive_money_screen.dart';
import '../presentation/send_money_screen/send_money_screen.dart';
import '../services/auth_service.dart';

class AppRoutes {
  static const String initial = '/dashboard-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String authenticationScreen = '/authentication-screen';
  static const String sendMoneyScreen = '/send-money-screen';
  static const String receiveMoneyScreen = '/receive-money-screen';
  static const String qrCodeDisplayScreen = '/qr-code-display-screen';
  static const String paymentConfirmationScreen =
      '/payment-confirmation-screen';

  static Map<String, WidgetBuilder> get routes {
    return {
      dashboardScreen: (context) {
        // Check authentication status
        if (AuthService.instance.isSignedIn) {
          return const DashboardScreen();
        } else {
          return const AuthenticationScreen();
        }
      },
      authenticationScreen: (context) => const AuthenticationScreen(),
      sendMoneyScreen: (context) => const SendMoneyScreen(),
      receiveMoneyScreen: (context) => const ReceiveMoneyScreen(),
      qrCodeDisplayScreen: (context) => const QrCodeDisplayScreen(),
      paymentConfirmationScreen: (context) => const PaymentConfirmationScreen(),
    };
  }
}
