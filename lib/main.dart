import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/asset_library/presentation/pages/dashboard_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppApiClient.init();

  AppApiClient.onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage(sessionExpired: true)),
          (_) => false,
    );
  };

  runApp(const BrandVaultApp());
}

class BrandVaultApp extends StatelessWidget {
  const BrandVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrandVault',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AppApiClient.hasToken ? const DashboardPage() : const LoginPage(),
    );
  }
}