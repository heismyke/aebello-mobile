import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/api_client.dart';
import 'screens/account_screen.dart';
import 'screens/esims_screen.dart';
import 'screens/explore_screen.dart';
import 'state/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final session = Session(api);
  await session.restore();
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: api),
        ChangeNotifierProvider.value(value: session),
      ],
      child: const AebelloApp(),
    ),
  );
}

class AebelloApp extends StatelessWidget {
  const AebelloApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp(title: 'Aebello', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const HomeShell());
}

/// Bottom navigation: Explore, My eSIMs, Account.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _tab,
      children: [
        const ExploreScreen(),
        EsimsScreen(visible: _tab == 1),
        const AccountScreen(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public), label: 'Explore'),
        NavigationDestination(
          icon: Icon(Icons.sim_card_outlined),
          selectedIcon: Icon(Icons.sim_card),
          label: 'My eSIMs',
        ),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
      ],
    ),
  );
}
