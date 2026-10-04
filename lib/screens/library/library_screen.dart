import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/colors.dart';

class LegalLibraryScreen extends StatefulWidget {
  const LegalLibraryScreen({super.key});

  @override
  State<LegalLibraryScreen> createState() => _LegalLibraryScreenState();
}

class _LegalLibraryScreenState extends State<LegalLibraryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _precedents = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. جلب المواد القانونية
      final articlesRes = await _supabase
          .from('legal_articles')
          .select()
          .or('content.ilike.%$cleanQuery%,law_name.ilike.%$cleanQuery%')
          .limit(50);

      // 2. جلب الاجتهادات القضائية
      final precedentsRes = await _supabase
          .from('judicial_precedents')
          .select()
          .or('principle.ilike.%$cleanQuery%,details.ilike.%$cleanQuery%')
          .limit(50);

      if (mounted) {
        setState(() {
          _articles = List<Map<String, dynamic>>.from(articlesRes);
          _precedents = List<Map<String, dynamic>>.from(precedentsRes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء البحث: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A), // كحلي غامق
            title: const Text('المكتبة القانونية والاجتهادات'),
            bottom: TabBar(
              indicatorColor: const Color(0xFF38BDF8), // أزرق سماوي
              labelColor: const Color(0xFF38BDF8),
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  icon: const Icon(Icons.menu_book),
                  text: 'المواد القانونية (${_articles.length})',
                ),
                Tab(
                  icon: const Icon(Icons.gavel),
                  text: 'الاجتهادات القضائية (${_precedents.length})',
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // شريط البحث
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن موضوع، مادة، أو اجتهاد (مثال: سرقة)...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _articles.clear();
                          _precedents.clear();
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _performSearch,
                ),
              ),

              // عرض النتائج بحسب التبويب النشط
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildArticlesList(),
                          _buildPrecedentsList(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // بطاقات المواد القانونية
  Widget _buildArticlesList() {
    if (_articles.isEmpty) {
      return const Center(child: Text('لا توجد مواد مطابقة للبحث'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _articles.length,
      itemBuilder: (context, i) {
        final a = _articles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      a['article_number'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    Text(
                      a['law_name'] ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  a['content'] ?? '',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // بطاقات الاجتهادات القضائية
  Widget _buildPrecedentsList() {
    if (_precedents.isEmpty) {
      return const Center(child: Text('لا توجد اجتهادات مطابقة للبحث'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _precedents.length,
      itemBuilder: (context, i) {
        final p = _precedents[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${p['decision_number']} / ${p['basis_number'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    Text(
                      p['court_chamber'] ?? 'محكمة النقض',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'المبدأ: ${p['principle'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.4),
                ),
                if (p['details'] != null && p['details'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p['details'],
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}