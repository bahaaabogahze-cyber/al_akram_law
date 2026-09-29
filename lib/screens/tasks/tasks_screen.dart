import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _cases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        LocalStore.getTasks(),
        LocalStore.getCases(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0];
        _cases = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('تعذر تحميل المهام: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _caseTitle(dynamic caseId) {
    if (caseId == null || caseId.toString().isEmpty) return 'بدون قضية';
    for (final c in _cases) {
      if (c['id'].toString() == caseId.toString()) {
        return (c['title'] ?? 'قضية').toString();
      }
    }
    return 'قضية غير موجودة';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'بدون تاريخ استحقاق';
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} - $h:$m';
  }

  Future<void> _showTaskDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final title = TextEditingController(text: existing?['title']?.toString() ?? '');
    final description = TextEditingController(text: existing?['description']?.toString() ?? '');
    String? selectedCaseId = existing?['caseId']?.toString() ?? existing?['case_id']?.toString();
    String priority = existing?['priority']?.toString() ?? 'normal';
    bool completed = existing?['completed'] == true;
    DateTime? dueDate = _parseDate(existing?['dueAt'] ?? existing?['due_at']);
    bool saving = false;
    final form = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'تعديل المهمة' : 'إضافة مهمة'),
            content: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'عنوان المهمة', prefixIcon: Icon(Icons.task_alt)),
                      validator: (v) => v == null || v.trim().isEmpty ? 'أدخل عنوان المهمة' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'الوصف', prefixIcon: Icon(Icons.notes)),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedCaseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'ربط بالقضية', prefixIcon: Icon(Icons.folder)),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('بدون قضية')),
                        ..._cases.map((c) => DropdownMenuItem<String?>(
                              value: c['id'].toString(),
                              child: Text((c['title'] ?? 'قضية').toString(), overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (value) => setDialogState(() => selectedCaseId = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'الأولوية', prefixIcon: Icon(Icons.flag)),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('منخفضة')),
                        DropdownMenuItem(value: 'normal', child: Text('عادية')),
                        DropdownMenuItem(value: 'high', child: Text('عالية')),
                      ],
                      onChanged: (value) => setDialogState(() => priority = value ?? 'normal'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final initial = dueDate ?? DateTime.now().add(const Duration(days: 1));
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate: initial,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date == null || !dialogContext.mounted) return;
                        final time = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(dueDate ?? DateTime.now()),
                        );
                        if (time != null) {
                          setDialogState(() => dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                        } else {
                          setDialogState(() => dueDate = DateTime(date.year, date.month, date.day, 9));
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'تاريخ الاستحقاق', prefixIcon: Icon(Icons.event)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDate(dueDate)),
                            if (dueDate != null)
                              IconButton(
                                tooltip: 'إزالة التاريخ',
                                onPressed: () => setDialogState(() => dueDate = null),
                                icon: const Icon(Icons.clear),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: completed,
                      title: const Text('مهمة منجزة'),
                      onChanged: (v) => setDialogState(() => completed = v ?? false),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!form.currentState!.validate()) return;
                        setDialogState(() => saving = true);
                        try {
                          final item = <String, dynamic>{
                            'id': existing?['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
                            'caseId': selectedCaseId,
                            'title': title.text.trim(),
                            'description': description.text.trim(),
                            'dueAt': dueDate?.toUtc().toIso8601String(),
                            'priority': priority,
                            'completed': completed,
                            'createdAt': existing?['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
                          };
                          await LocalStore.saveTask(item);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          await _load();
                          if (!mounted) return;
                          _snack(isEdit ? 'تم تعديل المهمة بنجاح' : 'تمت إضافة المهمة بنجاح');
                        } catch (e) {
                          if (dialogContext.mounted) setDialogState(() => saving = false);
                          _snack('تعذر حفظ المهمة: $e');
                        }
                      },
                child: Text(isEdit ? 'حفظ' : 'إضافة'),
              ),
            ],
          );
          },
        ),
      );
    } finally {
      title.dispose();
      description.dispose();
    }
  }

  Future<void> _delete(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المهمة'),
        content: Text('هل تريد حذف "${task['title'] ?? 'المهمة'}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await LocalStore.deleteTask(task['id'].toString());
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      _snack('تم حذف المهمة');
    } catch (e) {
      _snack('تعذر حذف المهمة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المهام'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('لا توجد مهام.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final t = _items[i];
                      final done = t['completed'] == true;
                      final due = _parseDate(t['dueAt'] ?? t['due_at']);
                      final now = DateTime.now();
                      final overdue = !done && due != null && due.isBefore(now);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Checkbox(
                            value: done,
                            onChanged: (v) async {
                              try {
                                await LocalStore.setTaskCompleted(t['id'].toString(), v ?? false);
                                if (!mounted) return;
                                await _load();
                              } catch (e) {
                                _snack('تعذر تحديث حالة المهمة: $e');
                              }
                            },
                          ),
                          title: Text(
                            t['title']?.toString() ?? '',
                            style: TextStyle(decoration: done ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if ((t['description']?.toString() ?? '').isNotEmpty) Text(t['description'].toString()),
                                const SizedBox(height: 4),
                                Text('القضية: ${_caseTitle(t['caseId'] ?? t['case_id'])}'),
                                Text(
                                  _formatDate(due),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: overdue ? Colors.red : null),
                                ),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _showTaskDialog(existing: t);
                              if (value == 'delete') _delete(t);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('تعديل')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة مهمة', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
