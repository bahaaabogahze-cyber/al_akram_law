import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../services/local_store.dart';
import 'add_case_screen.dart';
import 'case_details_screen.dart';
import 'lawsuit_requirements_screen.dart';

class CasesScreen extends StatefulWidget {
  const CasesScreen({super.key});
  @override
  State<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends State<CasesScreen> {
  List<Map<String, dynamic>> _cases = [];
  String _query = '';
  String _status = 'الكل';
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _filteredCases = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _loading = false;

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await LocalStore.getCases();
      if (mounted) {
        setState(() {
          _cases = data;
          _applyFilter();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر تحميل القضايا: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    _filteredCases = _cases.where((c) {
      final text =
          '${c['title'] ?? ''} ${c['caseNumber'] ?? ''} ${c['client'] ?? ''} ${c['court'] ?? ''}'
              .toLowerCase();
      final matchesQuery = q.isEmpty || text.contains(q);
      final matchesStatus = _status == 'الكل' || c['status'] == _status;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        _query = value;
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('القضايا'),
        actions: [
          IconButton(
            tooltip: 'دليل الأوراق والطوابع',
            icon: const Icon(Icons.rule_folder_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LawsuitRequirementsScreen(),
                ),
              );
            },
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading && _cases.isEmpty ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              textDirection: TextDirection.rtl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث برقم القضية أو اسم الموكل أو المحكمة',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['الكل', 'جارية', 'مؤجلة', 'منتهية']
                  .map((s) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(s),
                          selected: _status == s,
                          onSelected: (_) {
                          setState(() {
                            _status = s;
                            _applyFilter();
                          });
                        },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _filteredCases.isEmpty
                ? _empty()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredCases.length,
                      itemBuilder: (_, i) => _caseCard(_filteredCases[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCaseScreen()));
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة قضية'),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('لا توجد قضايا مطابقة'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCaseScreen()));
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('إنشاء أول قضية'),
            ),
          ],
        ),
      );

  Widget _caseCard(Map<String, dynamic> c) {
    final status = c['status'] ?? 'جارية';
    final color = status == 'منتهية' ? Colors.grey : status == 'مؤجلة' ? Colors.orange : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CaseDetailsScreen(caseId: c['id'].toString())),
          );
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(Icons.folder, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c['title'] ?? 'قضية', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('رقم القضية: ${c['caseNumber'] ?? '-'}'),
                    Text('الموكل: ${c['client'] ?? '-'}'),
                    Text('المحكمة: ${c['court'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Chip(label: Text(status), backgroundColor: color.withValues(alpha: .12)),
            ],
          ),
        ),
      ),
    );
  }
}