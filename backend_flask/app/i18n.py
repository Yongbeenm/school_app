from flask import g

# Khmer-only translations (no English UI)
TRANSLATIONS = {
  "km": {
    "app_name": "ប្រព័ន្ធគ្រប់គ្រងពិន្ទុសិស្ស",
    "login": "ចូលប្រើប្រាស់",
    "logout": "ចាកចេញ",
    "username": "ឈ្មោះអ្នកប្រើ",
    "password": "ពាក្យសម្ងាត់",
    "role": "តួនាទី",
    "admin": "អ្នកគ្រប់គ្រង",
    "teacher": "គ្រូ",
    "student": "សិស្ស",
    "dashboard": "ផ្ទាំងគ្រប់គ្រង",
    "admin_dashboard": "ផ្ទាំងអ្នកគ្រប់គ្រង",
    "teacher_dashboard": "ផ្ទាំងគ្រូ",
    "my_dashboard": "ផ្ទាំងសិស្ស",
    "students": "សិស្ស",
    "teachers": "គ្រូ",
    "classes": "ថ្នាក់/បន្ទប់",
    "class": "ថ្នាក់",
    "room": "បន្ទប់/ថ្នាក់",
    "subjects": "មុខវិជ្ជា",
    "subject": "មុខវិជ្ជា",
    "terms": "ប្រចាំខែ",
    "term": "ប្រចាំខែ",
    "marks": "ពិន្ទុ",
    "score": "ពិន្ទុ",
    "average": "មធ្យមភាគ",
    "rank": "ចំណាត់ថ្នាក់",
    "ranking": "ចំណាត់ថ្នាក់",
    "results": "លទ្ធផល",
    "print": "បោះពុម្ព",
    "actions": "សកម្មភាព",
    "create": "បង្កើត",
    "delete": "លុប",
    "save": "រក្សាទុក",
    "select": "ជ្រើសរើស",
    "full_name": "ឈ្មោះពេញ",
    "student_code": "លេខសម្គាល់សិស្ស",
    "confirm_delete": "តើអ្នកប្រាកដថាចង់លុបមែនទេ?",
    "no_data": "មិនមានទិន្នន័យ",
    "help": "ជំនួយ",
    "hints": "សេចក្តីណែនាំ",
    "autosave": "រក្សាទុកស្វ័យប្រវត្តិ",
    "saved": "បានរក្សាទុក",
    "saving": "កំពុងរក្សាទុក...",
    "teacher_students": "សិស្សរបស់ខ្ញុំ",
    "save_marks": "រក្សាទុកពិន្ទុ",
    "weight": "ទំងន់",
    "name": "ឈ្មោះ",
    "optional": "(ស្រេចចិត្ត)",

    "absent": "អវត្តមាន",
    "permission": "សុំច្បាប់",
    "note": "កំណត់សម្គាល់",
    "trackbook": "សៀវភៅតាមដាន",
    "print_one": "បោះពុម្ពម្នាក់មួយ",
    "month": "ប្រចាំខែ",
    "save_auto": "រក្សាទុកស្វ័យប្រវត្តិ",
    "back": "ត្រឡប់ក្រោយ",
  }
}

def get_lang():
    # Khmer only
    return "km"

def t(key: str) -> str:
    lang = get_lang()
    return TRANSLATIONS.get(lang, {}).get(key, key)

def inject_i18n():
    g.lang = get_lang()
    return {"t": t, "lang": g.lang}
