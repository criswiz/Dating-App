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
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  final apiClient = ApiClient(
    baseUrl: const String.fromEnvironment('API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000'),
    tokenGetter: () async => authProvider.token,
  );
  final authService = AuthService(apiClient: apiClient);
  authProvider.setService(authService);

  runApp(MyApp(authProvider: authProvider, apiClient: apiClient, authService: authService));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ApiClient apiClient;
  final AuthService authService;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.apiClient,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthService>.value(value: authService),
      ],
      child: MaterialApp(
        title: 'Dating App',
        theme: AppTheme.light(),
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
  const _AuthGate();

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
  const HomeShell({super.key});

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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.pink,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore_rounded),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              activeIcon: Icon(Icons.favorite_rounded),
              label: 'Matches',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
