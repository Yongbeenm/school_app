# API Endpoints (Flask Backend)

Base URL: http://127.0.0.1:5001

Health:
- GET /api/health

Auth:
- POST /api/login  {username,password} -> {token, role}
- GET /api/me  (Authorization: Bearer token)

Admin:
- GET/POST /api/admin/classes
- PUT/DELETE /api/admin/classes/<id>
- GET/POST /api/admin/teachers
- PUT/DELETE /api/admin/teachers/<teacher_id>
- GET/POST /api/admin/students
- PUT/DELETE /api/admin/students/<student_id>
- GET /api/admin/terms
- GET /api/admin/ranking?class_id=&term_id=

Teacher:
- GET /api/teacher/terms
- GET /api/teacher/subjects
- GET/POST /api/teacher/students
- DELETE /api/teacher/students/<student_id>
- GET /api/teacher/marks?term_id=&subject_id=
- POST /api/teacher/marks
- GET /api/teacher/attendance?term_id=
- POST /api/teacher/attendance
- GET /api/teacher/ranking?term_id=

Student:
- GET /api/student/terms
- GET /api/student/overview?term_id=
