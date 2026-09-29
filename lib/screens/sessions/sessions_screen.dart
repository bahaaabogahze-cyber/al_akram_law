import 'package:flutter/material.dart';
import '../../services/local_store.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // قائمة الجلسات (تُحمَّل من قاعدة البيانات للمستخدم الحالي)
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _cases = [];
  bool _loading = true;

  static const _palette = <Color>[
    Color(0xFF071A33),
    Colors.orange,
    Colors.purple,
    Colors.green,
    Colors.teal,
    Colors.brown,
  ];

  static const _timeOptions = <String>[
    '08:00 ص', '09:00 ص', '10:00 ص', '11:00 ص',
    '12:00 م', '01:00 م', '02:00 م', '03:00 م',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final hearings = await LocalStore.getHearings();
      final cases = await LocalStore.getCases();
      final sessions = hearings.map(_fromStore).whereType<Map<String, dynamic>>().toList()
        ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _cases = cases;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('تعذر تحميل الجلسات: $e', Colors.red);
    }
  }

  Map<String, dynamic>? _fromStore(Map<String, dynamic> h) {
    final raw = h['hearingAt']?.toString();
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed == null) return null;
    final date = parsed.toLocal();
    final key = (h['caseId'] ?? h['court'] ?? h['id'] ?? '').toString();
    final color = _palette[key.codeUnits.fold<int>(0, (a, b) => a + b) % _palette.length];
    return {
      'id': h['id'].toString(),
      'caseId': h['caseId']?.toString(),
      'court': (h['court'] ?? '').toString(),
      'client': (h['client'] ?? '').toString(),
      'caseNumber': (h['caseNumber'] ?? '').toString(),
      'reason': (h['title'] ?? '').toString(),
      'notes': (h['notes'] ?? '').toString(),
      'time': _formatTime(date),
      'date': date,
      'color': color,
      'status': (h['status'] ?? 'قادمة').toString(),
      'createdAt': h['createdAt'],
    };
  }

  String _formatTime(DateTime d) {
    final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$m ${d.hour >= 12 ? 'م' : 'ص'}';
  }

  DateTime _combine(DateTime day, String time) {
    final parts = time.split(' ');
    final hm = parts[0].split(':');
    var h = int.tryParse(hm[0]) ?? 9;
    final m = hm.length > 1 ? int.tryParse(hm[1]) ?? 0 : 0;
    final pm = parts.length > 1 && parts[1] == 'م';
    if (pm && h < 12) h += 12;
    if (!pm && h == 12) h = 0;
    return DateTime(day.year, day.month, day.day, h, m);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // جلسات اليوم المحدد
  List<Map<String, dynamic>> get _selectedDaySessions {
    return _sessions.where((session) {
      final sessionDate = session['date'] as DateTime;
      return sessionDate.year == _selectedDay.year &&
          sessionDate.month == _selectedDay.month &&
          sessionDate.day == _selectedDay.day;
    }).toList();
  }

  // جلسات اليوم
  List<Map<String, dynamic>> get _todaySessions {
    final now = DateTime.now();
    return _sessions.where((session) {
      final sessionDate = session['date'] as DateTime;
      return sessionDate.year == now.year &&
          sessionDate.month == now.month &&
          sessionDate.day == now.day;
    }).toList();
  }

  // جلسات الغد
  List<Map<String, dynamic>> get _tomorrowSessions {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _sessions.where((session) {
      final sessionDate = session['date'] as DateTime;
      return sessionDate.year == tomorrow.year &&
          sessionDate.month == tomorrow.month &&
          sessionDate.day == tomorrow.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('📅 الجلسات والمواعيد'),
        backgroundColor: const Color(0xFF071A33),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSessionDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // التقويم
            _buildCalendar(),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_sessions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'لا توجد جلسات بعد. اضغط "إضافة جلسة" لإضافة أول جلسة.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            const SizedBox(height: 8),

            // جلسات اليوم
            if (_todaySessions.isNotEmpty) ...[
              _buildSectionHeader('🔴 جلسات اليوم', _todaySessions.length),
              ..._todaySessions.map((s) => _buildSessionCard(s)),
            ],

            // جلسات الغد
            if (_tomorrowSessions.isNotEmpty) ...[
              _buildSectionHeader('🟡 جلسات الغد', _tomorrowSessions.length),
              ..._tomorrowSessions.map((s) => _buildSessionCard(s)),
            ],

            // جلسات اليوم المحدد
            if (!_isSameDate(_selectedDay, DateTime.now())) ...[
              _buildSectionHeader(
                '📌 جلسات ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                _selectedDaySessions.length,
              ),
              if (_selectedDaySessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'لا توجد جلسات في هذا اليوم',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ..._selectedDaySessions.map((s) => _buildSessionCard(s)),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSessionDialog(),
        backgroundColor: const Color(0xFF071A33),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة جلسة',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // رأس التقويم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF071A33),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 18),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  _getMonthName(_focusedDay.month) +
                      ' ${_focusedDay.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // أيام الأسبوع
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['أح', 'إث', 'ث', 'أر', 'خ', 'ج', 'س']
                  .map((day) => Text(
                        day,
                        style: const TextStyle(
                          color: Color(0xFF071A33),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ))
                  .toList(),
            ),
          ),

          // أيام الشهر
          _buildMonthDays(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildMonthDays() {
    final firstDay =
        DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final firstWeekday = firstDay.weekday % 7;

    List<Widget> dayWidgets = [];

    // أيام فارغة في البداية
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // أيام الشهر
    for (int day = 1; day <= lastDay.day; day++) {
      final date =
          DateTime(_focusedDay.year, _focusedDay.month, day);
      final isSelected = date.year == _selectedDay.year &&
          date.month == _selectedDay.month &&
          date.day == _selectedDay.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      // هل يوجد جلسة في هذا اليوم
      final hasSession = _sessions.any((session) {
        final sessionDate = session['date'] as DateTime;
        return sessionDate.year == date.year &&
            sessionDate.month == date.month &&
            sessionDate.day == date.day;
      });

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() => _selectedDay = date);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF071A33)
                  : isToday
                      ? const Color(0xFFD4AF37)
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected || isToday
                        ? Colors.white
                        : Colors.black,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                if (hasSession)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF071A33),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: dayWidgets,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF071A33),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF071A33),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final color = session['color'] as Color;
    return GestureDetector(
      onTap: () => _showSessionDetails(session),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(right: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // الوقت
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session['time'],
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // التفاصيل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['court'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '👤 ${session['client']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '📋 ${session['reason']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '🔢 ${session['caseNumber']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // أيقونة التفاصيل
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    final color = session['color'] as Color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gavel, color: color, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session['court'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF071A33),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(Icons.person, 'الموكل', session['client'], color),
              _detailRow(Icons.numbers, 'رقم القضية',
                  session['caseNumber'], color),
              _detailRow(
                  Icons.access_time, 'الوقت', session['time'], color),
              _detailRow(Icons.description, 'سبب الجلسة',
                  session['reason'], color),
              _detailRow(Icons.calendar_today, 'التاريخ',
                  _dateLabel(session['date'] as DateTime), color),
              if (_caseTitle(session['caseId']) != null)
                _detailRow(Icons.folder, 'القضية المرتبطة',
                    _caseTitle(session['caseId'])!, color),
              if ((session['notes'] as String).isNotEmpty)
                _detailRow(Icons.notes, 'ملاحظات', session['notes'], color),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSessionDialog(existing: session);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSession(session['id'].toString());
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('حذف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('إغلاق'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF071A33),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(
      IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSession(String id) async {
    try {
      await LocalStore.deleteHearing(id);
      await _load();
      _snack('تم حذف الجلسة بنجاح', Colors.red);
    } catch (e) {
      _snack('تعذر حذف الجلسة: $e', Colors.red);
    }
  }

  String _dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String? _caseTitle(dynamic caseId) {
    if (caseId == null) return null;
    for (final c in _cases) {
      if (c['id'].toString() == caseId.toString()) {
        return (c['title'] ?? '').toString();
      }
    }
    return null;
  }

  void _showAddSessionDialog() => _showSessionDialog();

  void _showSessionDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final courtController = TextEditingController(text: existing?['court'] ?? '');
    final clientController = TextEditingController(text: existing?['client'] ?? '');
    final caseNumberController = TextEditingController(text: existing?['caseNumber'] ?? '');
    final reasonController = TextEditingController(text: existing?['reason'] ?? '');
    final notesController = TextEditingController(text: existing?['notes'] ?? '');
    String selectedTime = existing?['time'] ?? '09:00 ص';
    DateTime selectedDate = existing != null ? existing['date'] as DateTime : _selectedDay;
    String? selectedCaseId = existing?['caseId'];
    if (selectedCaseId != null && !_cases.any((c) => c['id'].toString() == selectedCaseId)) {
      selectedCaseId = null;
    }
    final timeItems = _timeOptions.contains(selectedTime) ? _timeOptions : [..._timeOptions, selectedTime];
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'تعديل الجلسة' : 'إضافة جلسة جديدة',
                style: const TextStyle(
                  color: Color(0xFF071A33),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      value: selectedCaseId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'القضية (اختياري)',
                        prefixIcon: const Icon(Icons.folder,
                            color: Color(0xFF071A33)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('بدون قضية')),
                        ..._cases.map((c) => DropdownMenuItem<String?>(
                              value: c['id'].toString(),
                              child: Text(
                                (c['title'] ?? '').toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (v) {
                        setDialogState(() => selectedCaseId = v);
                        if (v == null) return;
                        final c = _cases.firstWhere((c) => c['id'].toString() == v);
                        courtController.text = (c['court'] ?? '').toString();
                        clientController.text = (c['client'] ?? '').toString();
                        caseNumberController.text = (c['caseNumber'] ?? '').toString();
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDialogField(courtController, 'اسم المحكمة',
                        Icons.account_balance),
                    const SizedBox(height: 12),
                    _buildDialogField(
                        clientController, 'اسم الموكل', Icons.person),
                    const SizedBox(height: 12),
                    _buildDialogField(caseNumberController, 'رقم القضية',
                        Icons.numbers),
                    const SizedBox(height: 12),
                    _buildDialogField(
                        reasonController, 'سبب الجلسة', Icons.description),
                    const SizedBox(height: 12),
                    _buildDialogField(notesController, 'ملاحظات', Icons.notes),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ الجلسة',
                          prefixIcon: const Icon(Icons.calendar_today,
                              color: Color(0xFF071A33)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_dateLabel(selectedDate)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedTime,
                      decoration: InputDecoration(
                        labelText: 'وقت الجلسة',
                        prefixIcon: const Icon(Icons.access_time,
                            color: Color(0xFF071A33)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: timeItems
                          .map((t) =>
                              DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => selectedTime = v!,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (courtController.text.trim().isEmpty ||
                              clientController.text.trim().isEmpty) {
                            return;
                          }
                          setDialogState(() => saving = true);
                          final reason = reasonController.text.trim();
                          try {
                            await LocalStore.saveHearing({
                              'id': existing?['id'] ??
                                  DateTime.now().microsecondsSinceEpoch.toString(),
                              'caseId': selectedCaseId,
                              'title': reason.isEmpty ? 'جلسة' : reason,
                              'court': courtController.text.trim(),
                              'client': clientController.text.trim(),
                              'caseNumber': caseNumberController.text.trim(),
                              'notes': notesController.text.trim(),
                              'hearingAt': _combine(selectedDate, selectedTime)
                                  .toUtc()
                                  .toIso8601String(),
                              'status': existing?['status'] ?? 'قادمة',
                              'createdAt': existing?['createdAt'] ??
                                  DateTime.now().toIso8601String(),
                            });
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (mounted) setState(() => _selectedDay = selectedDate);
                            await _load();
                            _snack(
                                isEdit
                                    ? '✅ تم تعديل الجلسة بنجاح'
                                    : '✅ تمت إضافة الجلسة بنجاح',
                                const Color(0xFF071A33));
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => saving = false);
                            }
                            _snack('تعذر حفظ الجلسة: $e', Colors.red);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF071A33),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(isEdit ? 'حفظ' : 'إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF071A33)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF071A33), width: 2),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return months[month - 1];
  }
}