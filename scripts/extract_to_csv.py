import csv
import glob
import os
import re
import pdfplumber

PDF_DIR = "./courses_pdf"
OUTPUT_CSV = "all_legal_articles_with_penalties.csv"

# نمط المواد المكتوبة بشكل عادي أو معكوس
PATTERN_NORMAL = re.compile(
    r'(?:المادة|مادة|م)\s*[\/|\(]?\s*(\d+[\/\d\w]*)\s*[\/|\)]?\s*[:|\-|\.]?\s*(.*?)(?=(?:المادة|مادة|م)\s*[\/|\(]?\s*\d+|\Z)',
    re.DOTALL,
)
PATTERN_REVERSED = re.compile(
    r'(\d+[\/\d\w]*)\s*[\/|\(]?\s*(?:ةداملا|ةدام)\s*[:|\-|\.]?\s*(.*?)(?=\d+\s*[\/|\(]?\s*(?:ةداملا|ةدام)|\Z)',
    re.DOTALL,
)

# أنماط التعرف على العقوبات ومددها
PENALTY_PATTERNS = [
    (
        r'(الإعدام|مادعإلا)',
        'إعدام',
        'عقوبة الإعدام',
    ),
    (
        r'(السجن المؤبد|دبؤملا نجسلا)',
        'جنائية (سجن مؤبد)',
        'السجن المؤبد',
    ),
    (
        r'(الاعتقال المؤبد|دبؤملا لاقتعالا)',
        'جنائية (اعتقال مؤبد)',
        'الاعتقال المؤبد',
    ),
    (
        r'(الاعتقال المؤقت|تقؤملا لاقتعالا)\s*(?:لمدة)?\s*([^\.،\n]*)',
        'جنائية (اعتقال مؤقت)',
        'الاعتقال المؤقت',
    ),
    (
        r'(السجن المؤقت|تقؤملا نجسلا)\s*(?:لمدة)?\s*([^\.،\n]*)',
        'جنائية (سجن مؤقت)',
        'السجن المؤقت',
    ),
    (
        r'(الحبس|سبحلا)\s*(?:من|لمدة)?\s*([^\.،\n]{3,40})',
        'جنحية (حبس)',
        'حبس',
    ),
]


def clean_text(text):
  if not text:
    return ''
  return ' '.join(text.split()).strip()


def extract_penalty_info(text):
  """استخراج نوع ومدة العقوبة والغرامة تلقائياً من نص المادة"""
  p_type = 'لا توجد عقوبة جزائية (نص تنظيمي/مدني)'
  p_duration = ''
  fine = ''

  # البحث عن الغرامات
  fine_match = re.search(r'(غرامة[^\.،\n]{3,50})', text)
  if fine_match:
    fine = clean_text(fine_match.group(1))

  # البحث عن العقوبات الجسدية والسالبة للحرية
  for pattern, p_t, default_dur in PENALTY_PATTERNS:
    m = re.search(pattern, text)
    if m:
      p_type = p_t
      if len(m.groups()) > 1 and m.group(2):
        p_duration = f'{default_dur} {clean_text(m.group(2))}'
      else:
        p_duration = default_dur
      break

  return p_type, p_duration, fine


def get_source_and_category(filename):
  """تحديد مصدر القانون وتصنيفه بناءً على اسم الملف"""
  name = filename.lower()
  if 'عقوبات' in name:
    return 'قانون العقوبات السوري', 'قانون جزائي عام/خاص'
  elif 'تنفيذ' in name or 'محاكمات' in name:
    return 'قانون أصول المحاكمات المدنية', 'قانون إجرائي'
  elif 'مدني' in name or 'التزام' in name or 'أملية' in name:
    return 'القانون المدني السوري', 'قانون موضوعي مدني'
  elif 'إداري' in name or 'اداري' in name:
    return 'القانون الإداري', 'قانون عام'
  elif 'دستور' in name or 'con' in name:
    return 'دستور الجمهورية العربية السورية', 'تشريع دستوري'
  elif 'دولي' in name or 'اقتصادي' in name:
    return 'معاهدات واتفاقيات دولية', 'قانون دولي'
  elif 'تجاري' in name or 'إفلاس' in name or 'شركات' in name:
    return 'قانون التجارة السوري', 'قانون تجاري'
  elif 'بينات' in name:
    return 'قانون البينات السوري', 'قانون إثبات'
  elif 'إرهاب' in name:
    return 'قانون مكافحة الإرهاب', 'تشريع جزائي خاص'
  return 'تشريع سوري', 'قوانين عامة'


def extract_from_file(file_path):
  filename = os.path.basename(file_path)
  course_name = os.path.splitext(filename)[0].replace('_', ' ')
  legal_source, source_category = get_source_and_category(filename)

  print(f'[*] جاري فحص واستخراج: {filename}...')
  full_text = ''
  try:
    with pdfplumber.open(file_path) as pdf:
      for page in pdf.pages:
        t = page.extract_text()
        if t:
          full_text += '\n' + t
  except Exception as e:
    print(f'[-] تعذر فتح {filename}: {e}')
    return []

  if not full_text.strip():
    return []

  extracted = []

  # البحث بالنمطين (العادي والمعكوس)
  matches = PATTERN_NORMAL.findall(full_text)
  used_pattern = 'normal'
  if not matches:
    matches = PATTERN_REVERSED.findall(full_text)
    used_pattern = 'reversed'

  for match in matches:
    art_num = clean_text(match[0])
    raw_content = clean_text(match[1])

    if len(raw_content) >= 15:
      title = 'نص تشريعي'
      if ':' in raw_content[:80]:
        title = raw_content.split(':', 1)[0][:60]
        body = raw_content.split(':', 1)[1]
      else:
        body = raw_content

      # استخراج تفاصيل العقوبة
      p_type, p_dur, fine = extract_penalty_info(body)

      keywords_val = f'{{قانون,"{course_name[:30]}","{p_type}"}}'

      extracted.append({
          'course_name': course_name,
          'legal_source': legal_source,
          'source_category': source_category,
          'article_number': art_num,
          'article_title': title,
          'article_text': body[:4000],
          'penalty_type': p_type,
          'penalty_duration': p_dur,
          'fine_amount': fine,
          'keywords': keywords_val,
          'effective_date': '',
          'official_source': '',
      })

  print(
      f'[+] تم استخراج {len(extracted)} مادة مع تفاصيل عقوباتها ومصادرها بنجاح.'
  )
  return extracted


def main():
  pdf_files = glob.glob(os.path.join(PDF_DIR, '*.pdf'))
  if not pdf_files:
    print(f'لم يتم العثور على ملفات في {PDF_DIR}')
    return

  all_results = []
  for f in pdf_files:
    all_results.extend(extract_from_file(f))

  fieldnames = [
      'course_name',
      'legal_source',
      'source_category',
      'article_number',
      'article_title',
      'article_text',
      'penalty_type',
      'penalty_duration',
      'fine_amount',
      'keywords',
      'effective_date',
      'official_source',
  ]

  with open(
      OUTPUT_CSV, mode='w', encoding='utf-8-sig', newline=''
  ) as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()
    for row in all_results:
      writer.writerow(row)

  print('=' * 60)
  print(f'اكتملت المعالجة الشاملة بنجاح!')
  print(f'إجمالي المواد المستخرجة: {len(all_results)}')
  print(f'الملف الشامل للعقوبات والمصادر: {OUTPUT_CSV}')
  print('=' * 60)


if __name__ == '__main__':
  main()