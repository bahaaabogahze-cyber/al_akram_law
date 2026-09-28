import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
import '../cases/cases_screen.dart';
import '../documents/documents_screen.dart';
import '../drafting/legal_drafting_screen.dart';
import '../library/library_screen.dart';
import '../notifications/notifications_screen.dart';
import '../research/legal_research_screen.dart';
import '../sessions/sessions_screen.dart';
import '../clients/clients_screen.dart';
import '../tasks/tasks_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
    HomeContent(onNavigate: (index) => setState(() => _currentIndex = index)),
    LibraryScreen(),
    SessionsScreen(),
    ClientsScreen(),
    const ProfileScreen(),
  ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'المكتبة'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'الجلسات'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'الموكلون'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const HomeContent({super.key, required this.onNavigate});
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _cases = 0, _documents = 0, _hearings = 0, _unread = 0;
  String _name = 'المحامي';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cases = await LocalStore.getCases();
    final docs = await LocalStore.getDocuments();
    final hearings = await LocalStore.getHearings();
    final notes = await LocalStore.getNotifications();
    final p = await SharedPreferencesHelper.get();
    if (mounted) {
      setState(() {
        _cases = cases.length;
        _documents = docs.length;
        _hearings = hearings.length;
        _unread = notes.where((n) => n['read'] != true).length;
        _name = p;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الأكرم للمحاماة'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  _load();
                },
              ),
              if (_unread > 0)
                Positioned(right: 8, top: 8, child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 9)),
                )),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF283593)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('مرحباً $_name 👋', style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
                const SizedBox(height: 5),
                const Text('الأكرم للمحاماة 🏛️', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('إدارة القضايا والبحث القانوني والمستندات في مكان واحد', style: TextStyle(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _stat('$_cases', 'القضايا', Icons.folder)),
              const SizedBox(width: 8),
              Expanded(child: _stat('$_hearings', 'الجلسات', Icons.gavel)),
              const SizedBox(width: 8),
              Expanded(child: _stat('$_documents', 'المستندات', Icons.description)),
            ]),
            const SizedBox(height: 20),
            const Text('أدوات المحامي', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 10),
            _grid([
              _tool(Icons.folder_copy, 'إدارة القضايا', () => _open(const CasesScreen())),
              _tool(Icons.search, 'بحث قانوني', () => _open(const LegalResearchScreen())),
              _tool(Icons.document_scanner, 'تصوير المستندات', () => _open(const DocumentsScreen())),
              _tool(Icons.calendar_month, 'الجلسات', () => widget.onNavigate(2)),
              _tool(Icons.people, 'الموكلون', () => widget.onNavigate(3)),
              _tool(Icons.menu_book, 'المكتبة القانونية', () => widget.onNavigate(1)),
              _tool(Icons.check_circle_outline, 'المهام', () => _open(const TasksScreen())),
              _tool(Icons.notifications, 'الإشعارات', () => _open(const NotificationsScreen())),
              _tool(Icons.edit_note, 'الصياغة القانونية', () => _open(const LegalDraftingScreen())),
              _tool(Icons.person, 'الملف الشخصي', () => widget.onNavigate(4)),
            ]),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0x121A237E), child: Icon(Icons.info_outline, color: AppColors.primary)),
                title: const Text('تنبيه قانوني'),
                subtitle: const Text('استخدم التطبيق لتنظيم العمل والبحث الأولي، وراجع دائماً النصوص الرسمية النافذة والتعديلات قبل اعتماد أي إجراء قانوني.'),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 5),
      child: Column(children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]),
    ),
  );

  Widget _grid(List<Widget> items) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: items,
  );

  Widget _tool(IconData icon, String title, VoidCallback onTap) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: AppColors.primary, size: 32),
        const SizedBox(height: 7),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    ),
  );

  void _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }
}

class SharedPreferencesHelper {
  static Future<String> get() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('userName') ?? 'المحامي';
  }
}
