import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/index.dart';

class CoWorklyApp extends StatelessWidget {
  const CoWorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'CoWorkly',
        theme: AppTheme.lightTheme,
        home: Consumer<AppProvider>(
          builder: (context, appProvider, _) {
            return appProvider.isLoggedIn
                ? const MainNavigationScreen()
                : const AuthScreen();
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
