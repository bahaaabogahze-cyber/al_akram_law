import 'package:flutter/material.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  // قائمة التصنيفات
  final List<String> _categories = [
    'الكل',
    'القانون المدني',
    'قانون العقوبات',
    'أصول المحاكمات',
    'قانون التجارة',
    'قانون العمل',
    'الأحوال الشخصية',
    'قانون الإيجارات',
    'القانون العقاري',
  ];

  // قاعدة بيانات المواد القانونية السورية
  final List<Map<String, dynamic>> _articles = [
    // القانون المدني
    {
      'number': 'المادة 1',
      'category': 'القانون المدني',
      'title': 'مصادر القانون',
      'content':
          'تسري النصوص التشريعية على جميع المسائل التي تتناولها هذه النصوص في لفظها أو في فحواها. فإذا لم يوجد نص تشريعي حكم القاضي بمقتضى مبادئ الشريعة الإسلامية، فإذا لم يوجد فبمقتضى العرف، فإذا لم يوجد فبمقتضى مبادئ القانون الطبيعي وقواعد العدالة.',
      'keywords': ['مصادر', 'تشريع', 'شريعة', 'عرف', 'عدالة'],
    },
    {
      'number': 'المادة 148',
      'category': 'القانون المدني',
      'title': 'حسن النية في تنفيذ العقود',
      'content':
          'يجب تنفيذ العقد طبقاً لما اشتمل عليه وبطريقة تتفق مع ما يوجبه حسن النية.',
      'keywords': ['عقد', 'تنفيذ', 'حسن النية', 'التزام'],
    },
    {
      'number': 'المادة 149',
      'category': 'القانون المدني',
      'title': 'تفسير العقد',
      'content':
          'إذا كانت عبارة العقد واضحة فلا يجوز الانحراف عنها من طريق تفسيرها للتعرف على إرادة المتعاقدين. أما إذا كان هناك محل لتفسير العقد فيجب البحث عن النية المشتركة للمتعاقدين دون الوقوف عند المعنى الحرفي للألفاظ.',
      'keywords': ['تفسير', 'عقد', 'إرادة', 'نية'],
    },
    {
      'number': 'المادة 158',
      'category': 'القانون المدني',
      'title': 'فسخ العقد',
      'content':
          'في العقود الملزمة للجانبين إذا لم يوفِ أحد المتعاقدين بالتزامه جاز للمتعاقد الآخر بعد إعذاره أن يطالب بتنفيذ العقد أو فسخه مع التعويض في الحالتين.',
      'keywords': ['فسخ', 'عقد', 'التزام', 'تعويض', 'إعذار'],
    },
    {
      'number': 'المادة 164',
      'category': 'القانون المدني',
      'title': 'المسؤولية التقصيرية',
      'content':
          'كل خطأ سبب ضرراً للغير يلزم من ارتكبه بالتعويض.',
      'keywords': ['مسؤولية', 'خطأ', 'ضرر', 'تعويض', 'تقصير'],
    },
    {
      'number': 'المادة 165',
      'category': 'القانون المدني',
      'title': 'الضرر الموجب للتعويض',
      'content':
          'يقدر القضاء مدى التعويض عن الضرر الذي لحق المضرور، وفقاً لأحكام المادتين 221 و222.',
      'keywords': ['تعويض', 'ضرر', 'قضاء', 'مضرور'],
    },
    {
      'number': 'المادة 220',
      'category': 'القانون المدني',
      'title': 'التعويض عن عدم التنفيذ',
      'content':
          'إذا لم يكن التعويض مقدراً في العقد أو في القانون، فالقاضي هو الذي يقدره ويشمل التعويض ما لحق الدائن من خسارة وما فاته من كسب.',
      'keywords': ['تعويض', 'تنفيذ', 'خسارة', 'كسب', 'قاضي'],
    },
    {
      'number': 'المادة 376',
      'category': 'القانون المدني',
      'title': 'التقادم العام',
      'content':
          'يتقادم الالتزام بانقضاء خمس عشرة سنة فيما عدا الحالات التي ورد فيها نص خاص في القانون وفيما عدا الاستثناءات التالية.',
      'keywords': ['تقادم', 'التزام', 'خمس عشرة سنة', 'انقضاء'],
    },

    // قانون العقوبات
    {
      'number': 'المادة 1',
      'category': 'قانون العقوبات',
      'title': 'مبدأ الشرعية',
      'content':
          'لا جريمة ولا عقوبة إلا بنص قانوني. لا يسري قانون العقوبات على ما وقع من الجرائم قبل نفاذه.',
      'keywords': ['جريمة', 'عقوبة', 'شرعية', 'قانون'],
    },
    {
      'number': 'المادة 192',
      'category': 'قانون العقوبات',
      'title': 'جريمة القتل العمد',
      'content':
          'من قتل إنساناً قصداً عوقب بالأشغال الشاقة المؤقتة من خمس عشرة إلى عشرين سنة.',
      'keywords': ['قتل', 'عمد', 'أشغال شاقة', 'عقوبة'],
    },
    {
      'number': 'المادة 208',
      'category': 'قانون العقوبات',
      'title': 'الاعتداء والإيذاء',
      'content':
          'كل من أوقع بقصد إيذاء أحد ضرباً أو جرحاً أو غيره من أعمال العنف أو القسر عوقب بالحبس من ثلاثة أشهر إلى ثلاث سنوات وبالغرامة.',
      'keywords': ['إيذاء', 'ضرب', 'جرح', 'عنف', 'حبس'],
    },
    {
      'number': 'المادة 621',
      'category': 'قانون العقوبات',
      'title': 'جريمة السرقة',
      'content':
          'كل من سرق شيئاً مملوكاً لغيره عوقب بالحبس من ستة أشهر إلى ثلاث سنوات وبغرامة لا تتجاوز مئة ليرة سورية.',
      'keywords': ['سرقة', 'ملكية', 'حبس', 'غرامة'],
    },

    // أصول المحاكمات المدنية
    {
      'number': 'المادة 1',
      'category': 'أصول المحاكمات',
      'title': 'حق التقاضي',
      'content':
          'حق التقاضي مكفول للناس كافة، ولكل شخص أهلية التقاضي إلا من أخرجه القانون منها.',
      'keywords': ['تقاضي', 'أهلية', 'حق', 'محكمة'],
    },
    {
      'number': 'المادة 85',
      'category': 'أصول المحاكمات',
      'title': 'تبليغ الخصوم',
      'content':
          'يجب أن يبلغ كل من الخصوم بالجلسة المحددة للنظر في الدعوى قبل انعقادها بوقت كافٍ لا يقل عن ثلاثة أيام.',
      'keywords': ['تبليغ', 'خصوم', 'جلسة', 'دعوى'],
    },

    // قانون العمل
    {
      'number': 'المادة 1',
      'category': 'قانون العمل',
      'title': 'نطاق التطبيق',
      'content':
          'تسري أحكام هذا القانون على العمال وأصحاب العمل في جميع المنشآت التي تمارس نشاطها في الجمهورية العربية السورية.',
      'keywords': ['عمال', 'أصحاب عمل', 'منشآت', 'نشاط'],
    },
    {
      'number': 'المادة 65',
      'category': 'قانون العمل',
      'title': 'إنهاء عقد العمل',
      'content':
          'لا يجوز لصاحب العمل فصل العامل إلا لأسباب مشروعة، وعليه في حالة الفصل التعسفي دفع تعويض للعامل.',
      'keywords': ['فصل', 'عامل', 'تعويض', 'تعسفي', 'إنهاء'],
    },

    // الأحوال الشخصية
    {
      'number': 'المادة 1',
      'category': 'الأحوال الشخصية',
      'title': 'الزواج وشروطه',
      'content':
          'الزواج عقد بين رجل وامرأة تحل له شرعاً غايته إنشاء رابطة الزوجية والتناسل وإقامة حياة مشتركة.',
      'keywords': ['زواج', 'عقد', 'زوجية', 'شروط'],
    },
    {
      'number': 'المادة 85',
      'category': 'الأحوال الشخصية',
      'title': 'الطلاق',
      'content':
          'الطلاق حل رابطة الزواج وفق أحكام هذا القانون. يقع الطلاق باللفظ الصريح الدال عليه.',
      'keywords': ['طلاق', 'زواج', 'حل', 'رابطة'],
    },

    // قانون الإيجارات
    {
      'number': 'المادة 1',
      'category': 'قانون الإيجارات',
      'title': 'تعريف عقد الإيجار',
      'content':
          'الإيجار عقد يلتزم المؤجر بمقتضاه أن يمكّن المستأجر من الانتفاع بشيء معين مدة معينة مقابل أجر معلوم.',
      'keywords': ['إيجار', 'عقد', 'مؤجر', 'مستأجر', 'أجر'],
    },
    {
      'number': 'المادة 25',
      'category': 'قانون الإيجارات',
      'title': 'فسخ عقد الإيجار لعدم الدفع',
      'content':
          'يحق للمؤجر طلب فسخ عقد الإيجار إذا امتنع المستأجر عن دفع الأجرة المتفق عليها بعد إنذاره بالدفع خلال خمسة عشر يوماً.',
      'keywords': ['فسخ', 'إيجار', 'أجرة', 'دفع', 'إنذار', 'مستأجر'],
    },

    // القانون العقاري
    {
      'number': 'المادة 1',
      'category': 'القانون العقاري',
      'title': 'الملكية العقارية',
      'content':
          'الملكية العقارية حق عيني يخول صاحبه صلاحية استعمال العقار واستثماره والتصرف فيه ضمن حدود القانون.',
      'keywords': ['ملكية', 'عقار', 'حق عيني', 'استعمال', 'تصرف'],
    },

    // قانون التجارة
    {
      'number': 'المادة 1',
      'category': 'قانون التجارة',
      'title': 'الأعمال التجارية',
      'content':
          'يعد عملاً تجارياً كل عمل يتعلق بشراء البضائع أو المنقولات بقصد بيعها أو تأجيرها سواء بيعت أو أجرت بحالتها أو بعد تحويلها وصنعها.',
      'keywords': ['تجارة', 'بضائع', 'شراء', 'بيع', 'أعمال تجارية'],
    },
  ];

  // فلترة المواد حسب البحث والتصنيف
  List<Map<String, dynamic>> get _filteredArticles {
    return _articles.where((article) {
      final matchesCategory = _selectedCategory == 'الكل' ||
          article['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          article['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          article['content']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          article['number']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (article['keywords'] as List).any((k) => k
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('📚 المكتبة القانونية السورية'),
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
                hintText: 'ابحث برقم المادة أو الموضوع أو كلمة مفتاحية...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
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

          // التصنيفات
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _categories[index] == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = _categories[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A237E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A237E),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // عدد النتائج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'النتائج: ${_filteredArticles.length} مادة',
                  style: const TextStyle(
                    color: Color(0xFF1A237E),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // قائمة المواد
          Expanded(
            child: _filteredArticles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'لا توجد نتائج',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredArticles.length,
                    itemBuilder: (context, index) {
                      final article = _filteredArticles[index];
                      return _buildArticleCard(article);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    Color categoryColor;
    switch (article['category']) {
      case 'القانون المدني':
        categoryColor = const Color(0xFF1A237E);
        break;
      case 'قانون العقوبات':
        categoryColor = Colors.red;
        break;
      case 'أصول المحاكمات':
        categoryColor = Colors.green;
        break;
      case 'قانون العمل':
        categoryColor = Colors.orange;
        break;
      case 'الأحوال الشخصية':
        categoryColor = Colors.purple;
        break;
      case 'قانون الإيجارات':
        categoryColor = Colors.teal;
        break;
      case 'القانون العقاري':
        categoryColor = Colors.brown;
        break;
      case 'قانون التجارة':
        categoryColor = Colors.indigo;
        break;
      default:
        categoryColor = const Color(0xFF1A237E);
    }

    return GestureDetector(
      onTap: () {
        _showArticleDetails(article, categoryColor);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            right: BorderSide(color: categoryColor, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article['number'],
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      article['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                article['content'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  article['category'],
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArticleDetails(
      Map<String, dynamic> article, Color categoryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
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
                  // مقبض السحب
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

                  // رقم المادة والتصنيف
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article['number'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article['category'],
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // العنوان
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الخط الفاصل
                  Divider(color: categoryColor.withOpacity(0.3)),
                  const SizedBox(height: 16),

                  // النص الكامل
                  const Text(
                    'نص المادة:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: categoryColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      article['content'],
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // الكلمات المفتاحية
                  const Text(
                    'الكلمات المفتاحية:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (article['keywords'] as List).map((keyword) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: categoryColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          keyword,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // زر الإغلاق
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}