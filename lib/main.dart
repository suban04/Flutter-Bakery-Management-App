import 'package:flutter/material.dart';
import 'package:jantabackery/core/constants/app_colors.dart';
import 'package:jantabackery/core/constants/app_settings.dart';

import 'package:jantabackery/features/bakery_b2b/screens/bakery_list_screen.dart';
import 'package:jantabackery/features/daily_sales/screens/quick_billing_screen.dart';

import 'package:jantabackery/features/reports/screens/monthly_report_screen.dart';
import 'package:jantabackery/features/special_orders/screens/order_list_screen.dart';
import 'package:jantabackery/features/splash/screens/splash_screen.dart';

import 'core/constants/app_strings.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CakeShopApp());
}

class CakeShopApp extends StatelessWidget {
  const CakeShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppSettings.shopName,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    QuickBillingScreen(),
    OrderListScreen(),
    BakeryListScreen(),
    MonthlyReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.cardSurface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.cake_outlined),
            selectedIcon: Icon(Icons.cake_rounded, color: AppColors.primary),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded, color: AppColors.primary),
            label: 'Khata',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment_rounded, color: AppColors.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}