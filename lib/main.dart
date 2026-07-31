import 'package:flutter/material.dart';
import 'package:pintarx/config/theme.dart';
import 'package:pintarx/features/analytic/presentation/providers/analytic_provider.dart';
import 'package:pintarx/features/customer/presentation/providers/customer_provider.dart';
import 'package:pintarx/features/product/presentation/providers/product_provider.dart';
import 'package:pintarx/features/sales_order/presentation/providers/sales_order_provider.dart';
import 'package:pintarx/pages/auth/intro_page.dart';
import 'package:pintarx/providers/connectivity_provider.dart';
import 'package:pintarx/providers/theme_provider.dart';
import 'package:pintarx/services/api_service.dart';
import 'package:pintarx/services/auth_service.dart';
import 'package:provider/provider.dart';
// import 'package:intl/date_symbol_data_local.dart'; // Tambahkan ini

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [MAIN] Initializing services...');

  // Init API service
  ApiService().init();

  // Load token dari storage dan set ke ApiService (kalau ada)
  final auth = AuthService();
  await auth.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔁 [MAIN] App resumed → Re-checking token');
      AuthService().initialize(); // reload token ke ApiService
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => SalesOrderProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Pintar - X',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const IntroPage(),
          );
        },
      ),
    );
  }
}
