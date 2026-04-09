import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login.dart';
import 'screens/signup.dart';
import 'screens/swipe.dart';
import 'screens/matches.dart';
import 'screens/profile.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ProxyProvider<AuthProvider, ApiClient>(
          update: (_, auth, __) => ApiClient(
            baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000'),
            tokenGetter: () async => auth.token,
          ),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, api, __) => AuthService(apiClient: api),
        ),
        ProxyProvider<AuthService, AuthProvider>(
          update: (_, service, authProvider) {
            authProvider ??= AuthProvider();
            authProvider.setService(service);
            authProvider.loadFromStorage();
            return authProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Dating App',
        theme: ThemeData(
          primarySwatch: Colors.pink,
          useMaterial3: false,
        ),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const _AuthGate(),
          '/signup': (ctx) => SignupScreen(),
          '/home': (ctx) => const HomeShell(),
        },
      ),
    );
  }
}

/// Redirects to /home if already logged in, otherwise shows LoginScreen.
class _AuthGate extends StatefulWidget {
  const _AuthGate({Key? key}) : super(key: key);

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _check();
    }
  }

  Future<void> _check() async {
    final auth = context.read<AuthProvider>();
    await auth.loadFromStorage();
    if (!mounted) return;
    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreen();
  }
}

/// Main shell with bottom navigation: Discover / Matches / Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({Key? key}) : super(key: key);

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _screens = [
    SwipeScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: Colors.pink,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
