# Student Marks System (Flask + SQLAlchemy)
## Features added (per request)
- Light UI (Bootstrap 5)
- Khmer language option (basic built-in i18n, no extra deps)
- Admin / Teacher / Student roles
- Admin can:
  - create/delete classes, subjects, terms, students, marks
  - create teacher accounts
  - assign teacher -> class + subject (teaching assignments)
- Teacher can:
  - choose term + class + subject (from assignments)
  - enter/update marks for students in that class
- Student can:
  - view marks, average, rank

## Run (Mac)
```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt

python3 manage.py create-db
python3 manage.py seed --admin-user admin --admin-pass admin123
python3 manage.py run
```
Open: http://127.0.0.1:5000/login

Admin: admin / admin123

## Language
Use the language switcher in the top navbar (English / ខ្មែរ).

## Run with run.py
```bash
python3 run.py
```

## Permissions
- Admin: manage Teachers / Students / Rooms(Classes) / Ranking
- Teacher: manage Students (own class), Subjects, Months (ប្រចាំខែ), Marks, Print Results & Ranking

## New in v4
- Student code auto-number (S0001, S0002...)
- Teacher marks auto-save while typing
- Help page with tabs

## Flutter API
- POST `/api/login`  {username, password} -> {token, role}
- Teacher:
  - GET `/api/teacher/terms`
  - GET `/api/teacher/subjects`
  - GET `/api/teacher/students`
  - POST `/api/teacher/students` {full_name}
  - DELETE `/api/teacher/students/<id>`
  - GET `/api/teacher/marks?term_id=&subject_id=`
  - POST `/api/teacher/marks` {student_id, term_id, subject_id, score}
  - POST `/api/teacher/attendance` {student_id, term_id, absent, permission, note}
  - GET `/api/teacher/ranking?term_id=`
- Student:
  - GET `/api/student/terms`
  - GET `/api/student/overview?term_id=`
