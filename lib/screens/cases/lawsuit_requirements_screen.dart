import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LawsuitRequirementsScreen extends StatefulWidget {
  const LawsuitRequirementsScreen({Key? key}) : super(key: key);

  @override
  State<LawsuitRequirementsScreen> createState() => _LawsuitRequirementsScreenState();
}

class _LawsuitRequirementsScreenState extends State<LawsuitRequirementsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requirements = [];
  List<Map<String, dynamic>> _filteredRequirements = [];
  bool _isLoading = true;
  String _selectedCategory = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  final Color primaryDark = const Color(0xFF0F172A); // كحلي غامق
  final Color cardBackground = const Color(0xFF1E293B); // كحلي متوسط للبطاقات
  final Color accentBlue = const Color(0xFF38BDF8); // أزرق فاتح / سماوي
  final Color goldAccent = const Color(0xFFFBBF24); // لمسة ذهبية

  @override
  void initState() {
    super.initState();
    _fetchRequirements();
  }

  Future<void> _fetchRequirements() async {
    try {
      final response = await _supabase
          .from('lawsuit_requirements')
          .select()
          .order('lawsuit_name', ascending: true);

      setState(() {
        _requirements = List<Map<String, dynamic>>.from(response);
        _filteredRequirements = _requirements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل البيانات: $e')),
      );
    }
  }

  void _filterData(String query) {
    setState(() {
      _filteredRequirements = _requirements.where((item) {
        final matchesQuery = item['lawsuit_name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            item['court'].toString().toLowerCase().contains(query.toLowerCase());
        final matchesCategory = _selectedCategory == 'الكل' || item['category'] == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  // دالة إرسال الأوراق المطلوبة إلى واتساب
  Future<void> _sendViaWhatsApp(Map<String, dynamic> item) async {
    final docsList = (item['required_docs'] as List).map((doc) => '▪ $doc').join('\n');
    
    final message = '''
السلام عليكم ورحمة الله،
تحية طيبة، مرفق إليكم قائمة بالأوراق والمستندات المطلوبة للبدء في إجراءات:
⚖️ *${item['lawsuit_name']}*
المحكمة المختصة: ${item['court']}

📄 *المستندات المطلوبة:*
$docsList

يرجى تجهيزها وتزويدنا بها في أقرب وقت لإتمام الإجراءات القضائية أصولاً.
''';

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse("whatsapp://send?text=$encodedMessage");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تطبيق واتساب غير مثبت على الجهاز')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: primaryDark,
          elevation: 0,
          title: const Text(
            'دليل متطلبات الدعاوى والطوابع',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // حقل البحث
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: _filterData,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الدعوى أو المحكمة...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: accentBlue),
                  filled: true,
                  fillColor: cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // شريط فلترة التصنيفات
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: ['الكل', 'مدني', 'شرعي', 'جزائي'].map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: accentBlue,
                      backgroundColor: cardBackground,
                      labelStyle: TextStyle(
                        color: isSelected ? primaryDark : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _filterData(_searchController.text);
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // قائمة الدعاوى
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: accentBlue))
                  : _filteredRequirements.isEmpty
                      ? const Center(
                          child: Text(
                            'لم يتم العثور على نتائج',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredRequirements.length,
                          itemBuilder: (context, index) {
                            final item = _filteredRequirements[index];
                            return _buildLawsuitCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawsuitCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        collapsedIconColor: accentBlue,
        iconColor: accentBlue,
        title: Text(
          item['lawsuit_name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Icon(Icons.gavel, size: 14, color: goldAccent),
              const SizedBox(width: 4),
              Text(
                item['court'],
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الأوراق المطلوبة
                Row(
                  children: [
                    Icon(Icons.description, size: 18, color: accentBlue),
                    const SizedBox(width: 8),
                    const Text(
                      'الأوراق والمستندات المطلوبة:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(item['required_docs'] as List).map(
                  (doc) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.white70)),
                        Expanded(
                          child: Text(
                            doc,
                            style: const TextStyle(color: Colors.white70, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: Colors.white12, height: 24),

                // الطوابع والرسوم
                Row(
                  children: [
                    Icon(Icons.confirmation_number, size: 18, color: goldAccent),
                    const SizedBox(width: 8),
                    const Text(
                      'الطوابع واللصاقات الإلزامية:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (item['required_stamps'] as List).map((stamp) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryDark,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: goldAccent.withOpacity(0.3)),
                      ),
                      child: Text(
                        stamp,
                        style: TextStyle(color: goldAccent, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),

                // الملاحظات الإجرائية
                if (item['procedural_notes'] != null) ...[
                  const Divider(color: Colors.white12, height: 24),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'تنبيه إجرائي: ${item['procedural_notes']}',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // زر إرسال للعميل عبر واتساب
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // لون واتساب الأخضر
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text(
                      'إرسال قائمة الأوراق للموكل عبر واتساب',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _sendViaWhatsApp(item),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}