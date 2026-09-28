import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  String _category = 'الكل';
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<String> _categories = const ['الكل'];
  final List<Map<String, dynamic>> _articles = [];
  static const int _pageSize = 50;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndArticles() async {
    try {
      final categories = await SupabaseService.getLegalCategories();
      if (!mounted) return;
      setState(() => _categories = ['الكل', ...categories]);
    } catch (_) {
      // The article request below will show the actionable error if Supabase is unavailable.
    }
    await _loadArticles(reset: true);
  }

  Future<void> _loadArticles({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _offset = 0;
        _articles.clear();
      });
    } else {
      if (_loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final category = _category == 'الكل' ? null : _category;
      final data = _query.isNotEmpty
          ? await SupabaseService.searchLegalArticles(_query, category: category, maxResults: 100)
          : await SupabaseService.browseLegalArticles(category: category, offset: _offset, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        if (reset) _articles.clear();
        _articles.addAll(data);
        _offset += data.length;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل المكتبة القانونية. تأكد من تطبيق migrations الخاصة بـ Supabase وتسجيل الدخول.');
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _runSearch() {
    _query = _searchController.text.trim();
    _loadArticles(reset: true);
  }

  Widget _penalty(Map<String, dynamic> a) {
    final type = (a['penalty_type'] ?? '').toString();
    final duration = (a['penalty_duration'] ?? '').toString();
    final fine = (a['fine_amount'] ?? '').toString();
    if (type.isEmpty && duration.isEmpty && fine.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(.10), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('العقوبة المستخرجة', style: TextStyle(fontWeight: FontWeight.bold)),
        if (type.isNotEmpty) Text('النوع: $type'),
        if (duration.isNotEmpty) Text('المدة: $duration'),
        if (fine.isNotEmpty) Text('الغرامة: $fine'),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('المكتبة القانونية السورية')),
    body: RefreshIndicator(
      onRefresh: () => _loadArticles(reset: true),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
          TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            onSubmitted: (_) => _runSearch(),
            decoration: InputDecoration(
              hintText: 'ابحث برقم المادة أو الموضوع أو كلمة مفتاحية...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _query = ''; _loadArticles(reset: true); }),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _categories.contains(_category) ? _category : 'الكل',
            decoration: const InputDecoration(labelText: 'المصدر / المقرر'),
            items: _categories.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) { if (v != null) { setState(() => _category = v); _loadArticles(reset: true); } },
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, height: 46, child: FilledButton.icon(onPressed: _loading ? null : _runSearch, icon: const Icon(Icons.search), label: const Text('بحث'))),
        ]))),
        const SizedBox(height: 8),
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('البيانات المعروضة مأخوذة من ملف المواد القانونية المضاف إلى قاعدة البيانات. يجب مراجعة النص الرسمي النافذ وآخر التعديلات قبل الاعتماد المهني.'))),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _articles.isEmpty && _error == null) const Padding(padding: EdgeInsets.all(30), child: Center(child: Text('لا توجد مواد مطابقة.'))),
        ..._articles.map((a) => Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
          leading: const CircleAvatar(child: Icon(Icons.gavel)),
          title: Text('${a['article_number'] ?? ''} — ${a['title'] ?? 'نص تشريعي'}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(a['source_title'] ?? a['course_name'] ?? ''),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Align(alignment: Alignment.centerRight, child: Text((a['content'] ?? '').toString())),
            _penalty(a),
            if ((a['legal_source'] ?? '').toString().isNotEmpty) Align(alignment: Alignment.centerRight, child: Text('المصدر القانوني: ${a['legal_source']}')),
            if ((a['official_reference'] ?? '').toString().isNotEmpty) Align(alignment: Alignment.centerRight, child: Text('المرجع الرسمي: ${a['official_reference']}')),
          ],
        ))),
        if (!_loading && _query.isEmpty && _articles.length >= _pageSize)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: SizedBox(height: 46, child: OutlinedButton(onPressed: _loadingMore ? null : () => _loadArticles(), child: _loadingMore ? const CircularProgressIndicator() : const Text('تحميل المزيد')))),
      ]),
    ),
  );
}
