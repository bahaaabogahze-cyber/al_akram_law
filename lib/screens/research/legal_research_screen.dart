import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/supabase_service.dart';

class LegalResearchScreen extends StatefulWidget {
  final String? initialText;

  const LegalResearchScreen({super.key, this.initialText});

  @override
  State<LegalResearchScreen> createState() => _LegalResearchScreenState();
}

class _LegalResearchScreenState extends State<LegalResearchScreen> {
  static const int _pageSize = 30;

  late final TextEditingController _controller;
  Timer? _debounce;
  String _category = 'الكل';
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];
  List<String> _categories = ['الكل'];
  int _offset = 0;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _loadCategories();
    if (_controller.text.trim().length >= 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search(reset: true));
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await SupabaseService.getLegalCategories();
      if (mounted) setState(() => _categories = ['الكل', ...data]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search({bool reset = true}) async {
    final q = _controller.text.trim();

    // Invalidate any older request first so a late response cannot restore
    // results after the user clears or changes the query.
    final requestId = ++_requestId;

    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _results = [];
        _offset = 0;
        _hasMore = false;
        _error = null;
      });
      return;
    }

    if (_loadingMore && !reset) return;
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _offset = 0;
        _hasMore = true;
        _results = [];
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final data = await SupabaseService.searchLegalArticles(
        q,
        category: _category == 'الكل' ? null : _category,
        maxResults: _pageSize,
        offset: _offset,
      );

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results.addAll(data);
        _offset += data.length;
        _hasMore = data.length == _pageSize;
        _error = null;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = 'تعذر تنفيذ البحث. تأكد من قاعدة البيانات وتسجيل الدخول.';
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

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      // Clear old results immediately; do not leave results from a previous
      // query visible while the user is deleting the search text.
      _requestId++;
      if (mounted) {
        setState(() {
          _results = [];
          _offset = 0;
          _hasMore = false;
          _error = null;
          _loading = false;
          _loadingMore = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _search(reset: true);
    });
  }

  String _formatRelevance(dynamic value) {
    final relevance = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return relevance == null ? '0' : relevance.toStringAsFixed(3);
  }

  Widget _resultCard(Map<String, dynamic> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.gavel)),
        title: Text(
          '${article['article_number'] ?? ''} — ${article['title'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${article['source_title'] ?? ''}  •  صلة: ${_formatRelevance(article['relevance'])}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: SelectableText((article['content'] ?? '').toString()),
          ),
          if ((article['official_reference'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child:
                  Text('المرجع الرسمي: ${article['official_reference']}'),
            ),
          if ((article['version_label'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Text('الإصدار: ${article['version_label']}'),
            ),
          if ((article['source_url'] ?? '').toString().isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: SelectableText(
                'رابط المصدر: ${article['source_url']}',
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _controller.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('البحث القانوني السوري')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'ابحث في المواد والمصادر القانونية المتاحة داخل النظام.',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 7,
                    textDirection: TextDirection.rtl,
                    onChanged: _onChanged,
                    onSubmitted: (_) => _search(reset: true),
                    decoration: const InputDecoration(
                      hintText:
                          'اكتب رقم المادة أو موضوع القضية أو الكلمات القانونية...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _categories.contains(_category) ? _category : 'الكل',
                    decoration: const InputDecoration(
                        labelText: 'تصفية حسب التصنيف / المصدر',
                        border: OutlineInputBorder()),
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
                      if (_controller.text.trim().isNotEmpty) {
                        _search(reset: true);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : () => _search(reset: true),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.search),
                      label: const Text('بحث'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'تنبيه مهني: نتائج البحث للمساعدة فقط. يجب مراجعة النص الرسمي النافذ وآخر التعديلات والاجتهاد القضائي قبل اعتماد أي إجراء أو مذكرة.',
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && hasQuery && _results.isEmpty && _error == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('لا توجد نتائج مطابقة.')),
            ),
          if (!_loading) ..._results.map(_resultCard),
          if (!_loading && _hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: _loadingMore
                      ? null
                      : () => _search(reset: false),
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
    );
  }
}
