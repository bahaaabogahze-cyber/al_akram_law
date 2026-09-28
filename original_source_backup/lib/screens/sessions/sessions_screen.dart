import 'package:flutter/material.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // قائمة الجلسات
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': 1,
      'court': 'محكمة البداية المدنية',
      'client': 'أحمد محمد السيد',
      'caseNumber': '2024/1234',
      'time': '10:00 ص',
      'reason': 'جلسة مرافعة',
      'date': DateTime.now(),
      'color': const Color(0xFF1A237E),
      'status': 'قادمة',
    },
    {
      'id': 2,
      'court': 'محكمة الاستئناف',
      'client': 'سمير خالد العلي',
      'caseNumber': '2024/5678',
      'time': '02:00 م',
      'reason': 'استئناف حكم ابتدائي',
      'date': DateTime.now(),
      'color': Colors.orange,
      'status': 'قادمة',
    },
    {
      'id': 3,
      'court': 'محكمة الأحوال الشخصية',
      'client': 'فاطمة علي حسن',
      'caseNumber': '2024/9012',
      'time': '11:00 ص',
      'reason': 'قضية طلاق',
      'date': DateTime.now().add(const Duration(days: 1)),
      'color': Colors.purple,
      'status': 'قادمة',
    },
    {
      'id': 4,
      'court': 'محكمة العمال',
      'client': 'خالد إبراهيم',
      'caseNumber': '2024/3456',
      'time': '09:00 ص',
      'reason': 'نزاع عمالي',
      'date': DateTime.now().add(const Duration(days: 2)),
      'color': Colors.green,
      'status': 'قادمة',
    },
  ];

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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('📅 الجلسات والمواعيد'),
        backgroundColor: const Color(0xFF1A237E),
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
            if (_selectedDay.day != DateTime.now().day) ...[
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
        backgroundColor: const Color(0xFF1A237E),
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
            color: Colors.black.withOpacity(0.05),
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
              color: Color(0xFF1A237E),
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
                          color: Color(0xFF1A237E),
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
                  ? const Color(0xFF1A237E)
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
                            : const Color(0xFF1A237E),
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
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
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
              color: Colors.black.withOpacity(0.05),
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
                  color: color.withOpacity(0.1),
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
                      color: color.withOpacity(0.1),
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
                        color: Color(0xFF1A237E),
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
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSession(session['id']);
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
                        backgroundColor: const Color(0xFF1A237E),
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
              color: color.withOpacity(0.1),
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

  void _deleteSession(int id) {
    setState(() {
      _sessions.removeWhere((s) => s['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف الجلسة بنجاح'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showAddSessionDialog() {
    final courtController = TextEditingController();
    final clientController = TextEditingController();
    final caseNumberController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedTime = '09:00 ص';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'إضافة جلسة جديدة',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: InputDecoration(
                    labelText: 'وقت الجلسة',
                    prefixIcon: const Icon(Icons.access_time,
                        color: Color(0xFF1A237E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    '08:00 ص', '09:00 ص', '10:00 ص', '11:00 ص',
                    '12:00 م', '01:00 م', '02:00 م', '03:00 م',
                  ]
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
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (courtController.text.isNotEmpty &&
                    clientController.text.isNotEmpty) {
                  setState(() {
                    _sessions.add({
                      'id': _sessions.length + 1,
                      'court': courtController.text,
                      'client': clientController.text,
                      'caseNumber': caseNumberController.text,
                      'time': selectedTime,
                      'reason': reasonController.text,
                      'date': _selectedDay,
                      'color': const Color(0xFF1A237E),
                      'status': 'قادمة',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تمت إضافة الجلسة بنجاح'),
                      backgroundColor: Color(0xFF1A237E),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إضافة'),
            ),
          ],
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
        prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1A237E), width: 2),
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