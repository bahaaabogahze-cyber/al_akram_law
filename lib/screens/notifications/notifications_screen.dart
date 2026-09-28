import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String,dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await LocalStore.getNotifications();
    if (mounted) setState(() => _items = data);
  }

  Future<void> _clear() async {
    for (final n in List<Map<String,dynamic>>.from(_items)) {
      await LocalStore.deleteNotification(n['id'].toString());
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (_items.isNotEmpty) IconButton(onPressed: () async { await LocalStore.markAllNotificationsRead(); _load(); }, icon: const Icon(Icons.done_all)),
          if (_items.isNotEmpty) IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 70, color: Colors.grey), SizedBox(height: 10), Text('لا توجد إشعارات')]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final n = _items[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0x121A237E), child: Icon(Icons.notifications, color: AppColors.primary)),
                    title: Text(n['title'] ?? ''),
                    subtitle: Text('${n['body'] ?? ''}\n${n['date'] ?? ''}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
