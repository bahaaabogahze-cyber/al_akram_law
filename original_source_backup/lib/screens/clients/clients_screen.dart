import 'package:flutter/material.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _clients = [
    {
      'id': 1,
      'name': 'أحمد محمد السيد',
      'phone': '0912345678',
      'email': 'ahmed@email.com',
      'specialty': 'قضية عقارية',
      'cases': ['قضية 2024/1234 - عقارية', 'قضية 2023/5678 - مدنية'],
      'notes': 'موكل قديم - يفضل التواصل صباحاً',
      'color': const Color(0xFF1A237E),
      'status': 'نشط',
    },
    {
      'id': 2,
      'name': 'سمير خالد العلي',
      'phone': '0923456789',
      'email': 'samir@email.com',
      'specialty': 'قضية استئناف',
      'cases': ['قضية 2024/5678 - استئناف'],
      'notes': 'قضية عاجلة',
      'color': Colors.orange,
      'status': 'نشط',
    },
    {
      'id': 3,
      'name': 'فاطمة علي حسن',
      'phone': '0934567890',
      'email': 'fatima@email.com',
      'specialty': 'أحوال شخصية',
      'cases': ['قضية 2024/9012 - طلاق'],
      'notes': 'تحتاج متابعة مستمرة',
      'color': Colors.purple,
      'status': 'نشط',
    },
    {
      'id': 4,
      'name': 'خالد إبراهيم محمود',
      'phone': '0945678901',
      'email': 'khaled@email.com',
      'specialty': 'قانون العمل',
      'cases': ['قضية 2024/3456 - عمالية'],
      'notes': 'نزاع مع صاحب العمل',
      'color': Colors.green,
      'status': 'نشط',
    },
    {
      'id': 5,
      'name': 'ريم سالم الأحمد',
      'phone': '0956789012',
      'email': 'reem@email.com',
      'specialty': 'قانون الإيجارات',
      'cases': ['قضية 2023/7890 - إيجار'],
      'notes': 'قضية منتهية',
      'color': Colors.teal,
      'status': 'منتهي',
    },
  ];

  List<Map<String, dynamic>> get _filteredClients {
    return _clients.where((client) {
      return _searchQuery.isEmpty ||
          client['name']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          client['phone']
              .toString()
              .contains(_searchQuery) ||
          client['specialty']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('👥 الموكلون'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // شريط البحث
          Container(
            color: const Color(0xFF1A237E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'ابحث باسم الموكل أو رقم الهاتف...',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF1A237E)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // إحصائيات
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '${_clients.length}',
                    'إجمالي الموكلين',
                    Icons.people,
                    const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${_clients.where((c) => c['status'] == 'نشط').length}',
                    'قضايا نشطة',
                    Icons.folder_open,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '${_clients.where((c) => c['status'] == 'منتهي').length}',
                    'قضايا منتهية',
                    Icons.folder,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // قائمة الموكلين
          Expanded(
            child: _filteredClients.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      return _buildClientCard(_filteredClients[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientDialog(),
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'إضافة موكل',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String number, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final color = client['color'] as Color;
    final isActive = client['status'] == 'نشط';

    return GestureDetector(
      onTap: () => _showClientDetails(client),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              // الصورة الرمزية
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    client['name'].toString().substring(0, 1),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // البيانات
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          client['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            client['status'],
                            style: TextStyle(
                              color:
                                  isActive ? Colors.green : Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${client['phone']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '⚖️ ${client['specialty']}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '📁 ${(client['cases'] as List).length} قضية',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientDetails(Map<String, dynamic> client) {
    final color = client['color'] as Color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
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

                  // رأس البطاقة
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            client['name'].toString().substring(0, 1),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            client['specialty'],
                            style: TextStyle(
                                color: color, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: color.withOpacity(0.3)),
                  const SizedBox(height: 12),

                  // بيانات الاتصال
                  _infoRow(Icons.phone, 'الهاتف', client['phone'], color),
                  _infoRow(Icons.email, 'البريد', client['email'], color),
                  _infoRow(Icons.gavel, 'التخصص',
                      client['specialty'], color),

                  const SizedBox(height: 16),

                  // القضايا
                  Text(
                    '📁 القضايا (${(client['cases'] as List).length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...(client['cases'] as List).map(
                    (case_) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        case_,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الملاحظات
                  const Text(
                    '📝 الملاحظات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      client['notes'],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // أزرار التواصل
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.phone),
                          label: const Text('اتصال'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
      },
    );
  }

  Widget _infoRow(
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
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final notesController = TextEditingController();
    String selectedSpecialty = 'القانون المدني';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'إضافة موكل جديد',
            style: TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(
                    nameController, 'الاسم الكامل', Icons.person),
                const SizedBox(height: 12),
                _buildDialogField(
                    phoneController, 'رقم الهاتف', Icons.phone,
                    isLTR: true,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _buildDialogField(
                    emailController, 'البريد الإلكتروني', Icons.email,
                    isLTR: true),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedSpecialty,
                  decoration: InputDecoration(
                    labelText: 'نوع القضية',
                    prefixIcon: const Icon(Icons.gavel,
                        color: Color(0xFF1A237E)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'القانون المدني',
                    'القانون الجزائي',
                    'الأحوال الشخصية',
                    'القانون التجاري',
                    'قانون العمل',
                    'القانون العقاري',
                    'قانون الإيجارات',
                  ]
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => selectedSpecialty = v!,
                ),
                const SizedBox(height: 12),
                _buildDialogField(
                    notesController, 'ملاحظات', Icons.notes),
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
                if (nameController.text.isNotEmpty &&
                    phoneController.text.isNotEmpty) {
                  setState(() {
                    _clients.add({
                      'id': _clients.length + 1,
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'email': emailController.text,
                      'specialty': selectedSpecialty,
                      'cases': [],
                      'notes': notesController.text,
                      'color': const Color(0xFF1A237E),
                      'status': 'نشط',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ تمت إضافة الموكل بنجاح'),
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
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isLTR = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: isLTR ? TextDirection.ltr : TextDirection.rtl,
      keyboardType: keyboardType,
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
}