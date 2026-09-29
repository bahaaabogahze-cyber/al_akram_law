import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const int _pageSize = 30;

  final _searchController = TextEditingController();
  Timer? _debounce;

  String _category = 'الكل';
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  List<String> _categories = const ['الكل'];
  final List<Map<String, dynamic>> _articles = [];
  int _offset = 0;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndArticles();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndArticles() async {
    try {
      final categories = await SupabaseService.getLegalCategories();
      if (!mounted) return;
      setState(() => _categories = ['الكل', ...categories]);
    } catch (_) {
      // The main query displays the actionable error.
    }
    await _loadArticles(reset: true);
  }

  Future<void> _loadArticles({bool reset = false}) async {
    if (_loadingMore && !reset) return;

    final requestId = ++_requestId;
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _offset = 0;
        _hasMore = true;
        _articles.clear();
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final category = _category == 'الكل' ? null : _category;
      final data = _query.isEmpty
          ? await SupabaseService.browseLegalArticles(
              category: category,
              offset: _offset,
              limit: _pageSize,
            )
          : await SupabaseService.searchLegalArticles(
              _query,
              category: category,
              maxResults: _pageSize,
              offset: _offset,
            );

      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (reset) _articles.clear();
        _articles.addAll(data);
        _offset += data.length;
        _hasMore = data.length == _pageSize;
        _error = null;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error =
            'تعذر تحميل المكتبة القانونية. تأكد من تشغيل migrations وتسجيل الدخول.';
        _hasMore = false;
      });
    } finally {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _runSearch() {
    _debounce?.cancel();
    _query = _searchController.text.trim();
    _loadArticles(reset: true);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final next = value.trim();
      if (next.length >= 2 || next.isEmpty) {
        _query = next;
        _loadArticles(reset: true);
      }
    });
  }

  Widget _penalty(Map<String, dynamic> article) {
    final type = (article['penalty_type'] ?? '').toString();
    final duration = (article['penalty_duration'] ?? '').toString();
    final fine = (article['fine_amount'] ?? '').toString();

    if (type.isEmpty && duration.isEmpty && fine.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('العقوبة المستخرجة',
              style: TextStyle(fontWeight: FontWeight.bold)),
          if (type.isNotEmpty) Text('النوع: $type'),
          if (duration.isNotEmpty) Text('المدة: $duration'),
          if (fine.isNotEmpty) Text('الغرامة: $fine'),
        ],
      ),
    );
  }

  Widget _articleCard(Map<String, dynamic> article) {
    final content = (article['content'] ?? '').toString();
    final title = (article['title'] ?? '').toString();
    final number = (article['article_number'] ?? '').toString();
    final source = (article['source_title'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.gavel)),
        title: Text(
          '$number — ${title.isEmpty ? 'نص تشريعي' : title}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(source, maxLines: 1, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SelectableText(content),
          ),
          _penalty(article),
          if ((article['legal_source'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text('المصدر القانوني: ${article['legal_source']}'),
            ),
          if ((article['official_reference'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text('المرجع الرسمي: ${article['official_reference']}'),
            ),
          if ((article['version_label'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text('الإصدار: ${article['version_label']}'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المكتبة القانونية السورية')),
      body: RefreshIndicator(
        onRefresh: () => _loadArticles(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _runSearch(),
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم المادة أو الموضوع أو كلمة مفتاحية...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _debounce?.cancel();
                            _query = '';
                            _loadArticles(reset: true);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(_category) ? _category : 'الكل',
                      decoration:
                          const InputDecoration(labelText: 'المصدر / المقرر'),
                      items: _categories
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _category = v);
                        _loadArticles(reset: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _runSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('بحث'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'هذه قاعدة بحث ومساعدة. يجب مراجعة النص الرسمي النافذ وآخر التعديلات قبل الاعتماد المهني.',
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red)),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _articles.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: Text('لا توجد مواد مطابقة.')),
              ),
            if (!_loading)
              ..._articles.map(_articleCard),
            if (!_loading && _hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed:
                        _loadingMore ? null : () => _loadArticles(),
                    child: _loadingMore
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('تحميل المزيد'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
