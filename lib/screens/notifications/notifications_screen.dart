import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await LocalStore.getNotifications();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل الإشعارات: $e')));
      }
    }
  }

  Future<void> _clear() async {
    for (final n in List<Map<String, dynamic>>.from(_items)) {
      await LocalStore.deleteNotification(n['id'].toString());
    }
    await _load();
  }

  String _relatedLabel(dynamic type) {
    switch (type?.toString()) {
      case 'task': return 'مهمة';
      case 'hearing': return 'جلسة';
      default: return 'تنبيه';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          if (_items.isNotEmpty) IconButton(onPressed: () async { await LocalStore.markAllNotificationsRead(); await _load(); }, icon: const Icon(Icons.done_all)),
          if (_items.isNotEmpty) IconButton(onPressed: _clear, icon: const Icon(Icons.delete_sweep_outlined)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_none, size: 70, color: Colors.grey), SizedBox(height: 10), Text('لا توجد إشعارات')]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      final read = n['read'] == true;
                      final type = n['relatedType'];
                      return Card(
                        color: read ? null : const Color(0xFFF3F6FF),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0x121A237E),
                            child: Icon(type == 'task' ? Icons.task_alt : type == 'hearing' ? Icons.event : Icons.notifications, color: AppColors.primary),
                          ),
                          title: Row(children: [Expanded(child: Text(n['title']?.toString() ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold))), Text(_relatedLabel(type), style: const TextStyle(fontSize: 11, color: Colors.grey))]),
                          subtitle: Text('${n['body'] ?? ''}\n${n['date'] ?? ''}'),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
