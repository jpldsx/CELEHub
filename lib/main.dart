import 'package:flutter/material.dart';
import 'api.dart';
import 'store.dart';
import 'screens/community_screen.dart';
import 'screens/saved_screen.dart';
import 'screens/support_screen.dart';
import 'screens/survey_screen.dart';
import 'screens/video_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const CeleHubApp());
}

class CeleHubApp extends StatelessWidget {
  const CeleHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F46E5);
    return MaterialApp(
      title: 'CELEHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const Gate(),
    );
  }
}

// the quick survey comes first, like on the website
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool _checking = true;
  bool _in = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (Store.minorFlagged) {
      setState(() {
        _checking = false;
        _in = false;
      });
      return;
    }
    final name = await Api.checkSession();
    if (!mounted) return;
    setState(() {
      _in = name.isNotEmpty;
      _checking = false;
    });
  }

  void _enter() => setState(() => _in = true);

  Future<void> _leave() async {
    await Api.signOut();
    if (!mounted) return;
    setState(() => _in = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_in) return SurveyScreen(onDone: _enter);
    return HomeShell(onSignOut: _leave);
  }
}

class HomeShell extends StatefulWidget {
  final Future<void> Function() onSignOut;
  const HomeShell({super.key, required this.onSignOut});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const VideoListScreen(page: 'study'),
      const VideoListScreen(page: 'break'),
      const SavedScreen(),
      CommunityScreen(onNeedSurvey: widget.onSignOut),
      SupportScreen(onSignOut: widget.onSignOut),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('CELEHub'),
        centerTitle: false,
      ),
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.coffee_outlined), selectedIcon: Icon(Icons.coffee), label: 'Break'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Support'),
        ],
      ),
    );
  }
}
