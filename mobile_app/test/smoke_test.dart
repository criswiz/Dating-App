import 'package:dating_app/main.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/services/api_client.dart';
import 'package:dating_app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login screen', (tester) async {
    final authProvider = AuthProvider();
    final apiClient = ApiClient(
      baseUrl: 'http://localhost:8000',
      tokenGetter: () async => authProvider.token,
    );
    final authService = AuthService(apiClient: apiClient);
    authProvider.setService(authService);

    await tester.pumpWidget(MyApp(
      authProvider: authProvider,
      apiClient: apiClient,
      authService: authService,
    ));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
