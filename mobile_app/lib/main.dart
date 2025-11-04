import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/swipe.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, auth, previous) => ApiClient(
            baseUrl: 'http://127.0.0.1:8000',
            tokenGetter: () async => auth.token,
          ),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, api, previous) => AuthService(apiClient: api),
        ),
        // Inject AuthService into existing AuthProvider instance
        ProxyProvider<AuthService, AuthProvider>(
          update: (_, service, authProvider) {
            authProvider ??= AuthProvider();
            authProvider.setService(service);
            // load token from storage after wiring
            authProvider.loadFromStorage();
            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Dating App',
        theme: ThemeData(primarySwatch: Colors.pink),
        initialRoute: '/',
        routes: {
          '/': (ctx) => LoginScreen(),
          '/signup': (ctx) => SignupScreen(),
          '/swipe': (ctx) => SwipeScreen(),
        },
      ),
    );
  }
}
