import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/colors.dart';

class LegalLibraryScreen extends StatefulWidget {
  const LegalLibraryScreen({super.key});

  @override
  State<LegalLibraryScreen> createState() =>
      _LegalLibraryScreenState();
}

class _LegalLibraryScreenState extends State<LegalLibraryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController =
      TextEditingController();

  List<Map<String, dynamic>> _articles = [];
  List<Map<String, dynamic>> _precedents = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      setState(() {
        _articles.clear();
        _precedents.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // البحث في المواد القانونية
      // أسماء الأعمدة مطابقة لقاعدة بيانات Supabase
      final articlesRes = await _supabase
          .from('legal_articles')
          .select()
          .or(
            'content.ilike.%$cleanQuery%,'
            'article_text.ilike.%$cleanQuery%,'
            'title.ilike.%$cleanQuery%,'
            'legal_source.ilike.%$cleanQuery%',
          )
          .limit(50);

      // البحث في الاجتهادات القضائية
      final precedentsRes = await _supabase
          .from('judicial_precedents')
          .select()
          .or(
            'principle.ilike.%$cleanQuery%,'
            'details.ilike.%$cleanQuery%',
          )
          .limit(50);

      if (mounted) {
        setState(() {
          _articles =
              List<Map<String, dynamic>>.from(articlesRes);

          _precedents =
              List<Map<String, dynamic>>.from(precedentsRes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء البحث: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            backgroundColor: const Color(0xFF0F172A),
            title: const Text(
              'المكتبة القانونية والاجتهادات',
            ),
            bottom: TabBar(
              indicatorColor: const Color(0xFF38BDF8),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText:
                        'ابحث عن موضوع، مادة، أو اجتهاد...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF38BDF8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _articles.clear();
                          _precedents.clear();
                          _hasSearched = false;
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
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
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

  // عرض المواد القانونية
  Widget _buildArticlesList() {
    if (_articles.isEmpty) {
      return Center(
        child: Text(
          _hasSearched
              ? 'لا توجد مواد قانونية مطابقة للبحث'
              : 'اكتب كلمة في مربع البحث للعثور على المواد القانونية',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _articles.length,
      itemBuilder: (context, i) {
        final a = _articles[i];

        final title = (a['title'] ?? '').toString();
        final legalSource =
            (a['legal_source'] ?? '').toString();

        final content =
            (a['content'] ?? '').toString().trim().isNotEmpty
                ? a['content'].toString()
                : (a['article_text'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المادة ${a['article_number'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: 16,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (legalSource.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    legalSource,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
                const Divider(height: 20),
                Text(
                  content.isNotEmpty
                      ? content
                      : 'لا يوجد نص متاح لهذه المادة',
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // عرض الاجتهادات القضائية
  Widget _buildPrecedentsList() {
    if (_precedents.isEmpty) {
      return Center(
        child: Text(
          _hasSearched
              ? 'لا توجد اجتهادات قضائية مطابقة للبحث'
              : 'اكتب كلمة في مربع البحث للعثور على الاجتهادات',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _precedents.length,
      itemBuilder: (context, i) {
        final p = _precedents[i];

        final principle =
            (p['principle'] ?? '').toString();

        final details =
            (p['details'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'القرار رقم: ${p['decision_number'] ?? ''}'
                  ' / ${p['basis_number'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'المحكمة: ${p['court_chamber'] ?? 'محكمة النقض'}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const Divider(height: 20),
                Text(
                  'المبدأ: $principle',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    details,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                    ),
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