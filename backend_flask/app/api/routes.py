from flask import request
from sqlalchemy import func

from . import api_bp
from .auth import make_token, require_token
from ..extensions import db
from ..models import User, Role, Student, Teacher, ClassRoom, Term, Subject, Mark, StudentMonthlyRecord
from ..services.ranking_service import rank_map_for_class
from ..teacher.routes import student_weighted_avg  # reuse existing function


def _json_student(s: Student):
    return {
        "id": s.id,
        "student_code": s.student_code,
        "full_name": s.full_name,
        "class_id": s.class_id,
    }

def _json_subject(sub: Subject):
    return {"id": sub.id, "name": sub.name, "weight": float(sub.weight or 1.0)}

def _json_term(t: Term):
    return {"id": t.id, "name": t.name}

@api_bp.post("/api/login")
def api_login():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    password = (data.get("password") or "").strip()
    user = User.query.filter_by(username=username).first()
    if not user or not user.check_password(password):
        return {"ok": False, "error": "invalid_login"}, 401
    token = make_token(user)
    # primary role for routing UI
    role = "STUDENT"
    if user.has_role("ADMIN"):
        role = "ADMIN"
    elif user.has_role("TEACHER"):
        role = "TEACHER"
    return {"ok": True, "token": token, "role": role}

@api_bp.get("/api/me")
@require_token("ADMIN", "TEACHER", "STUDENT")
def api_me():
    u = request.api_user  # type: ignore
    return {"ok": True, "user": {"id": u.id, "username": u.username, "roles": [r.name for r in u.roles]}}

# -------- Teacher APIs --------
def _teacher_and_classroom(user: User):
    teacher = Teacher.query.get(user.teacher_id) if user.teacher_id else None
    classroom = ClassRoom.query.get(teacher.class_id) if teacher and teacher.class_id else None
    return teacher, classroom

@api_bp.get("/api/teacher/terms")
@require_token("TEACHER")
def t_terms():
    return {"ok": True, "terms": [_json_term(t) for t in Term.query.order_by(Term.name.asc()).all()]}

@api_bp.get("/api/teacher/subjects")
@require_token("TEACHER")
def t_subjects():
    return {"ok": True, "subjects": [_json_subject(s) for s in Subject.query.order_by(Subject.name.asc()).all()]}

@api_bp.get("/api/teacher/students")
@require_token("TEACHER")
def t_students():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name.asc()).all()
    return {"ok": True, "classroom": {"id": classroom.id, "name": classroom.name}, "students": [_json_student(s) for s in students]}

@api_bp.post("/api/teacher/students")
@require_token("TEACHER")
def t_students_create():
    from ..services.code_service import next_student_code
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    data = request.get_json(silent=True) or {}
    full_name = (data.get("full_name") or "").strip()
    if not full_name:
        return {"ok": False, "error": "missing_name"}, 400
    student = Student(student_code=next_student_code(), full_name=full_name, class_id=classroom.id)
    db.session.add(student)
    db.session.commit()
    return {"ok": True, "student": _json_student(student)}

@api_bp.delete("/api/teacher/students/<int:student_id>")
@require_token("TEACHER")
def t_students_delete(student_id: int):
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        return {"ok": False, "error": "not_found"}, 404
    Mark.query.filter_by(student_id=s.id).delete()
    StudentMonthlyRecord.query.filter_by(student_id=s.id).delete()
    db.session.delete(s)
    db.session.commit()
    return {"ok": True}

@api_bp.get("/api/teacher/marks")
@require_token("TEACHER")
def t_marks():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    term_id = request.args.get("term_id", type=int)
    subject_id = request.args.get("subject_id", type=int)
    if not term_id or not subject_id:
        return {"ok": False, "error": "missing_term_subject"}, 400
    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name.asc()).all()
    marks = Mark.query.filter_by(term_id=term_id, subject_id=subject_id).all()
    mark_map = {m.student_id: float(m.score) for m in marks}
    # attendance data for that term
    recs = StudentMonthlyRecord.query.filter_by(term_id=term_id).all()
    monthly_map = {r.student_id: {"absent": int(r.absent), "permission": int(r.permission), "note": r.note or ""} for r in recs}
    return {
        "ok": True,
        "students": [_json_student(s) for s in students],
        "scores": mark_map,
        "monthly": monthly_map,
    }

@api_bp.post("/api/teacher/marks")
@require_token("TEACHER")
def t_marks_save_one():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    data = request.get_json(silent=True) or {}
    student_id = int(data.get("student_id") or 0)
    term_id = int(data.get("term_id") or 0)
    subject_id = int(data.get("subject_id") or 0)
    score = data.get("score")
    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        return {"ok": False, "error": "invalid_student"}, 400
    if not term_id or not subject_id:
        return {"ok": False, "error": "missing_term_subject"}, 400

    # empty => delete
    if score is None or str(score).strip() == "":
        m = Mark.query.filter_by(student_id=student_id, term_id=term_id, subject_id=subject_id).first()
        if m:
            db.session.delete(m)
            db.session.commit()
        return {"ok": True, "deleted": True}

    try:
        val = float(score)
    except Exception:
        return {"ok": False, "error": "bad_score"}, 400

    m = Mark.query.filter_by(student_id=student_id, term_id=term_id, subject_id=subject_id).first()
    if m:
        m.score = val
    else:
        db.session.add(Mark(student_id=student_id, term_id=term_id, subject_id=subject_id, score=val))
    db.session.commit()
    return {"ok": True}


@api_bp.get("/api/teacher/attendance")
@require_token("TEACHER")
def t_attendance_get():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    term_id = request.args.get("term_id", type=int)
    if not term_id:
        return {"ok": False, "error": "missing_term"}, 400
    recs = StudentMonthlyRecord.query.filter_by(term_id=term_id).all()
    m = {r.student_id: {"absent": int(r.absent), "permission": int(r.permission), "note": r.note or ""} for r in recs}
    return {"ok": True, "monthly": m}

@api_bp.post("/api/teacher/attendance")
@require_token("TEACHER")
def t_attendance_save():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    data = request.get_json(silent=True) or {}
    student_id = int(data.get("student_id") or 0)
    term_id = int(data.get("term_id") or 0)
    absent = int(data.get("absent") or 0)
    permission = int(data.get("permission") or 0)
    note = (data.get("note") or "").strip()

    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        return {"ok": False, "error": "invalid_student"}, 400
    if not term_id:
        return {"ok": False, "error": "missing_term"}, 400

    rec = StudentMonthlyRecord.query.filter_by(student_id=student_id, term_id=term_id).first()
    if not rec:
        rec = StudentMonthlyRecord(student_id=student_id, term_id=term_id, absent=0, permission=0, note="")
        db.session.add(rec)
    rec.absent = max(0, absent)
    rec.permission = max(0, permission)
    rec.note = note
    db.session.commit()
    return {"ok": True}

@api_bp.get("/api/teacher/ranking")
@require_token("TEACHER")
def t_ranking():
    u = request.api_user  # type: ignore
    _, classroom = _teacher_and_classroom(u)
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400
    term_id = request.args.get("term_id", type=int)
    if not term_id:
        return {"ok": False, "error": "missing_term"}, 400
    students = Student.query.filter_by(class_id=classroom.id).all()
    rows = []
    rank_map = rank_map_for_class(classroom.id, term_id)
    for s in students:
        avg = student_weighted_avg(s.id, term_id)
        rows.append({"student_id": s.id, "student_code": s.student_code, "full_name": s.full_name, "average": avg})
    rows.sort(key=lambda r: (-(r["average"] or 0), r["full_name"]))
    # attach rank
    for r in rows:
        r["rank"] = rank_map.get(r["student_id"])
    return {"ok": True, "classroom": {"id": classroom.id, "name": classroom.name}, "rows": rows}

# -------- Student APIs --------
@api_bp.get("/api/student/terms")
@require_token("STUDENT")
def s_terms():
    return {"ok": True, "terms": [_json_term(t) for t in Term.query.order_by(Term.name.asc()).all()]}

@api_bp.get("/api/student/overview")
@require_token("STUDENT")
def s_overview():
    u = request.api_user  # type: ignore
    if not u.student_id:
        return {"ok": False, "error": "not_linked"}, 400
    term_id = request.args.get("term_id", type=int)
    if not term_id:
        return {"ok": False, "error": "missing_term"}, 400
    student = Student.query.get(u.student_id)
    if not student:
        return {"ok": False, "error": "not_found"}, 404

    subjects = Subject.query.order_by(Subject.name.asc()).all()
    marks = Mark.query.filter_by(student_id=student.id, term_id=term_id).all()
    mark_map = {m.subject_id: float(m.score) for m in marks}
    avg = student_weighted_avg(student.id, term_id)
    rank = rank_map_for_class(student.class_id, term_id).get(student.id)
    rec = StudentMonthlyRecord.query.filter_by(student_id=student.id, term_id=term_id).first()

    return {
        "ok": True,
        "student": _json_student(student),
        "term_id": term_id,
        "subjects": [_json_subject(s) for s in subjects],
        "scores": {str(k): v for k, v in mark_map.items()},
        "average": avg,
        "rank": rank,
        "attendance": {
            "absent": int(rec.absent) if rec else 0,
            "permission": int(rec.permission) if rec else 0,
            "note": rec.note if rec else "",
        }
    }
