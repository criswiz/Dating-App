import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SwipeScreen extends StatelessWidget {
  final auth = AuthService();

  SwipeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Discover')),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<dynamic>?>(
                future: auth.fetchProfiles(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
                  if (!snap.hasData || snap.data == null)
                    return Center(child: Text('No profiles'));
                  final profiles = snap.data!;
                  return ListView.builder(
                    itemCount: profiles.length,
                    itemBuilder: (ctx, i) {
                      final p = profiles[i];
                      return Card(
                        margin: EdgeInsets.all(12),
                        child: ListTile(
                          title: Text(p['name'] ?? 'Unknown'),
                          subtitle: Text(p['bio'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.clear, color: Colors.red),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(Icons.favorite, color: Colors.green),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
