from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required, current_user
from . import teacher_bp
from ..extensions import db
from ..models import Term, Student, Subject, Mark, Teacher, ClassRoom, User, Role, user_roles, StudentMonthlyRecord
from ..services.authz import require_role
from ..services.code_service import next_student_code
from ..services.ranking_service import class_ranking_rows, student_weighted_avg, rank_map_for_class

def _get_or_create_role(name: str) -> Role:
    role = Role.query.filter_by(name=name).first()
    if not role:
        role = Role(name=name)
        db.session.add(role)
        db.session.commit()
    return role

def _delete_user(user: User):
    db.session.execute(user_roles.delete().where(user_roles.c.user_id == user.id))
    db.session.delete(user)

def _my_teacher() -> Teacher:

    if not current_user.teacher_id:
        return None
    return Teacher.query.get(current_user.teacher_id)

def _my_classroom() -> ClassRoom:
    t = _my_teacher()
    if not t or not t.class_id:
        return None
    return ClassRoom.query.get(t.class_id)

@teacher_bp.get("/dashboard")
@login_required
@require_role("TEACHER")
def dashboard():
    teacher = _my_teacher()
    classroom = _my_classroom()
    if not classroom:
        return render_template("teacher/no_class.html", teacher=teacher), 400

    terms = Term.query.order_by(Term.id.asc()).all()
    subjects = Subject.query.order_by(Subject.name.asc()).all()

    term_id = request.args.get("term_id", type=int)
    if not term_id and terms:
        term_id = terms[-1].id
    subject_id = request.args.get("subject_id", type=int)
    if not subject_id and subjects:
        subject_id = subjects[0].id

    term = Term.query.get(term_id) if term_id else None
    subject = Subject.query.get(subject_id) if subject_id else None

    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name).all()
    existing_marks = {}
    if term and subject:
        marks = Mark.query.filter_by(term_id=term.id, subject_id=subject.id).all()
        existing_marks = {m.student_id: m for m in marks}

    return render_template(
        "teacher/dashboard.html",
        teacher=teacher,
        classroom=classroom,
        terms=terms,
        subjects=subjects,
        selected_term=term,
        selected_subject=subject,
        students=students,
        existing_marks=existing_marks,
    )

@teacher_bp.post("/marks/save")
@login_required
@require_role("TEACHER")
def save_marks():
    teacher = _my_teacher()
    classroom = _my_classroom()
    if not classroom:
        flash("គ្រូមិនទាន់មានថ្នាក់កំណត់", "danger")
        return redirect(url_for("teacher.dashboard"))

    term_id = request.form.get("term_id", type=int)
    subject_id = request.form.get("subject_id", type=int)
    if not term_id or not subject_id:
        flash("ខ្វះប្រចាំខែ ឬ មុខវិជ្ជា", "danger")
        return redirect(url_for("teacher.dashboard"))

    students = Student.query.filter_by(class_id=classroom.id).all()
    for s in students:
        key = f"score_{s.id}"
        val = (request.form.get(key, "") or "").strip()
        if val == "":
            continue
        try:
            score_f = float(val)
        except ValueError:
            continue

        mark = Mark.query.filter_by(student_id=s.id, subject_id=subject_id, term_id=term_id).first()
        if mark:
            mark.score = score_f
        else:
            db.session.add(Mark(student_id=s.id, subject_id=subject_id, term_id=term_id, score=score_f))

    db.session.commit()
    flash("បានរក្សាទុកពិន្ទុរួចរាល់", "success")
    return redirect(url_for("teacher.dashboard", term_id=term_id, subject_id=subject_id))

# ---------- Teacher manage students (only own class) ----------
@teacher_bp.get("/students")
@login_required
@require_role("TEACHER")
def students():
    classroom = _my_classroom()
    if not classroom:
        return render_template("teacher/no_class.html"), 400
    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name).all()
    return render_template("teacher/students.html", classroom=classroom, students=students)

@teacher_bp.post("/students")
@login_required
@require_role("TEACHER")
def students_create():
    classroom = _my_classroom()
    if not classroom:
        flash("គ្រូមិនទាន់មានថ្នាក់កំណត់", "danger")
        return redirect(url_for("teacher.students"))

    full_name = (request.form.get("full_name") or "").strip()
    username = (request.form.get("username") or "").strip()
    password = (request.form.get("password") or "").strip()

    if not full_name:
        flash("ត្រូវបញ្ចូលឈ្មោះ", "danger")
        return redirect(url_for("teacher.students"))

    student_code = next_student_code()

    student = Student(student_code=student_code, full_name=full_name, class_id=classroom.id)
    db.session.add(student)
    db.session.flush()

    # Optional login
    if password:
        if not username:
            username = student_code.lower()
        if User.query.filter_by(username=username).first():
            flash("ឈ្មោះអ្នកប្រើមានរួចហើយ", "warning")
            db.session.rollback()
            return redirect(url_for("teacher.students"))

        user = User(username=username, student_id=student.id, teacher_id=None)
        user.set_password(password)
        student_role = _get_or_create_role("STUDENT")
        user.roles.append(student_role)
        db.session.add(user)

    db.session.commit()
    flash("បានបន្ថែមសិស្សរួចរាល់", "success")
    return redirect(url_for("teacher.students"))


@teacher_bp.post("/students/<int:student_id>/delete")
@login_required
@require_role("TEACHER")
def students_delete(student_id: int):
    classroom = _my_classroom()
    if not classroom:
        flash("មិនទាន់បានកំណត់ថ្នាក់សម្រាប់គ្រូ", "danger")
        return redirect(url_for("teacher.students"))

    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("teacher.students"))

    Mark.query.filter_by(student_id=student_id).delete()
    u = User.query.filter_by(student_id=student_id).first()
    if u:
        _delete_user(u)
    db.session.delete(s)
    db.session.commit()
    flash("បានលុបសិស្សរួចរាល់", "success")
    return redirect(url_for("teacher.students"))

# ---------- Teacher ranking + print ----------
@teacher_bp.get("/ranking")
@login_required
@require_role("TEACHER")
def ranking():
    classroom = _my_classroom()
    if not classroom:
        return render_template("teacher/no_class.html"), 400

    terms = Term.query.order_by(Term.id.asc()).all()
    term_id = request.args.get("term_id", type=int)
    if not term_id and terms:
        term_id = terms[-1].id
    term = Term.query.get(term_id) if term_id else None

    rows = class_ranking_rows(classroom.id, term.id) if term else []
    return render_template("teacher/ranking.html", classroom=classroom, terms=terms, selected_term=term, rows=rows)

@teacher_bp.get("/print/results")
@login_required
@require_role("TEACHER")
def print_results():
    classroom = _my_classroom()
    if not classroom:
        return "មិនទាន់បានកំណត់ថ្នាក់សម្រាប់គ្រូ", 400

    term_id = request.args.get("term_id", type=int)
    term = Term.query.get(term_id) if term_id else None
    if not term:
        return "ខ្វះប្រចាំខែ", 400

    subjects = Subject.query.order_by(Subject.name.asc()).all()
    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name).all()

    # marks map: (student_id, subject_id) -> score
    marks = Mark.query.filter(Mark.term_id == term.id).all()
    mark_map = {(m.student_id, m.subject_id): m.score for m in marks}

    # avg + rank
    avg_map = {s.id: student_weighted_avg(s.id, term.id) for s in students}
    rank_map = rank_map_for_class(classroom.id, term.id)

    return render_template(
        "teacher/print_results.html",
        classroom=classroom,
        term=term,
        subjects=subjects,
        students=students,
        mark_map=mark_map,
        avg_map=avg_map,
        rank_map=rank_map,
        monthly_map={r.student_id: r for r in StudentMonthlyRecord.query.filter_by(term_id=term.id).all()},
    )

@teacher_bp.get("/print/ranking")
@login_required
@require_role("TEACHER")
def print_ranking():
    classroom = _my_classroom()
    if not classroom:
        return "មិនទាន់បានកំណត់ថ្នាក់សម្រាប់គ្រូ", 400

    term_id = request.args.get("term_id", type=int)
    term = Term.query.get(term_id) if term_id else None
    if not term:
        return "ខ្វះប្រចាំខែ", 400

    rows = class_ranking_rows(classroom.id, term.id)
    return render_template("teacher/print_ranking.html", classroom=classroom, term=term, rows=rows)


# ---------- Teacher manage subjects ----------
@teacher_bp.get("/subjects")
@login_required
@require_role("TEACHER")
def subjects():
    subjects = Subject.query.order_by(Subject.name.asc()).all()
    return render_template("teacher/subjects.html", subjects=subjects)

@teacher_bp.post("/subjects")
@login_required
@require_role("TEACHER")
def subjects_create():
    name = (request.form.get("name") or "").strip()
    weight = (request.form.get("weight") or "1.0").strip()
    if not name:
        flash("ត្រូវបញ្ចូលឈ្មោះមុខវិជ្ជា", "danger")
        return redirect(url_for("teacher.subjects"))
    try:
        weight_f = float(weight)
    except ValueError:
        flash("ទំងន់ត្រូវតែជាលេខ", "danger")
        return redirect(url_for("teacher.subjects"))

    if Subject.query.filter_by(name=name).first():
        flash("មុខវិជ្ជានេះមានរួចហើយ", "warning")
        return redirect(url_for("teacher.subjects"))

    db.session.add(Subject(name=name, weight=weight_f))
    db.session.commit()
    flash("បានបង្កើតមុខវិជ្ជារួចរាល់", "success")
    return redirect(url_for("teacher.subjects"))

@teacher_bp.post("/subjects/<int:subject_id>/delete")
@login_required
@require_role("TEACHER")
def subjects_delete(subject_id: int):
    sub = Subject.query.get(subject_id)
    if not sub:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("teacher.subjects"))
    # delete related marks
    Mark.query.filter_by(subject_id=subject_id).delete()
    db.session.delete(sub)
    db.session.commit()
    flash("បានលុបមុខវិជ្ជារួចរាល់", "success")
    return redirect(url_for("teacher.subjects"))

# ---------- Teacher manage months (Terms) ----------
@teacher_bp.get("/months")
@login_required
@require_role("TEACHER")
def months():
    months = Term.query.order_by(Term.name.asc()).all()
    return render_template("teacher/months.html", months=months)

@teacher_bp.post("/months")
@login_required
@require_role("TEACHER")
def months_create():
    name = (request.form.get("name") or "").strip()
    if not name:
        flash("ត្រូវបញ្ចូលប្រចាំខែ", "danger")
        return redirect(url_for("teacher.months"))
    if Term.query.filter_by(name=name).first():
        flash("ប្រចាំខែនេះមានរួចហើយ", "warning")
        return redirect(url_for("teacher.months"))
    db.session.add(Term(name=name))
    db.session.commit()
    flash("បានបង្កើតប្រចាំខែរួចរាល់", "success")
    return redirect(url_for("teacher.months"))

@teacher_bp.post("/months/<int:term_id>/delete")
@login_required
@require_role("TEACHER")
def months_delete(term_id: int):
    t = Term.query.get(term_id)
    if not t:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("teacher.months"))
    Mark.query.filter_by(term_id=term_id).delete()
    db.session.delete(t)
    db.session.commit()
    flash("បានលុបប្រចាំខែរួចរាល់", "success")
    return redirect(url_for("teacher.months"))


@teacher_bp.post("/marks/autosave")
@login_required
@require_role("TEACHER")
def marks_autosave():
    classroom = _my_classroom()
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400

    data = request.get_json(silent=True) or {}
    student_id = int(data.get("student_id") or 0)
    term_id = int(data.get("term_id") or 0)
    subject_id = int(data.get("subject_id") or 0)
    score_raw = (data.get("score") or "").strip()

    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        return {"ok": False, "error": "invalid_student"}, 400

    if not term_id or not subject_id:
        return {"ok": False, "error": "missing_term_subject"}, 400

    # Empty = delete mark
    if score_raw == "":
        mark = Mark.query.filter_by(student_id=student_id, subject_id=subject_id, term_id=term_id).first()
        if mark:
            db.session.delete(mark)
            db.session.commit()
        return {"ok": True, "deleted": True}

    try:
        score = float(score_raw)
    except ValueError:
        return {"ok": False, "error": "bad_score"}, 400

    mark = Mark.query.filter_by(student_id=student_id, subject_id=subject_id, term_id=term_id).first()
    if mark:
        mark.score = score
    else:
        db.session.add(Mark(student_id=student_id, subject_id=subject_id, term_id=term_id, score=score))

    db.session.commit()
    return {"ok": True}
def _monthly_record(student_id: int, term_id: int) -> StudentMonthlyRecord:
    rec = StudentMonthlyRecord.query.filter_by(student_id=student_id, term_id=term_id).first()
    if not rec:
        rec = StudentMonthlyRecord(student_id=student_id, term_id=term_id, absent=0, permission=0, note="")
        db.session.add(rec)
        db.session.commit()
    return rec



@teacher_bp.get("/trackbook")
@login_required
@require_role("TEACHER")
def trackbook():
    classroom = _my_classroom()
    if not classroom:
        return render_template("teacher/no_class.html"), 400

    terms = Term.query.order_by(Term.name.asc()).all()
    term_id = request.args.get("term_id", type=int) or (terms[0].id if terms else None)
    term = Term.query.get(term_id) if term_id else None
    if not term:
        flash("ខ្វះប្រចាំខែ", "danger")
        return redirect(url_for("teacher.dashboard"))

    students = Student.query.filter_by(class_id=classroom.id).order_by(Student.full_name.asc()).all()
    recs = StudentMonthlyRecord.query.filter_by(term_id=term.id).all()
    rec_map = {r.student_id: r for r in recs}

    return render_template(
        "teacher/trackbook.html",
        classroom=classroom,
        teacher=_my_teacher(),
        terms=terms,
        selected_term=term,
        students=students,
        rec_map=rec_map,
    )

@teacher_bp.post("/trackbook/autosave")
@login_required
@require_role("TEACHER")
def trackbook_autosave():
    classroom = _my_classroom()
    if not classroom:
        return {"ok": False, "error": "no_class"}, 400

    data = request.get_json(silent=True) or {}
    student_id = int(data.get("student_id") or 0)
    term_id = int(data.get("term_id") or 0)
    absent = data.get("absent")
    permission = data.get("permission")
    note = (data.get("note") or "")

    s = Student.query.get(student_id)
    if not s or s.class_id != classroom.id:
        return {"ok": False, "error": "invalid_student"}, 400

    term = Term.query.get(term_id) if term_id else None
    if not term:
        return {"ok": False, "error": "missing_term"}, 400

    def to_int(x):
        try:
            return int(x)
        except Exception:
            return 0

    rec = StudentMonthlyRecord.query.filter_by(student_id=student_id, term_id=term.id).first()
    if not rec:
        rec = StudentMonthlyRecord(student_id=student_id, term_id=term.id, absent=0, permission=0, note="")
        db.session.add(rec)

    rec.absent = max(0, to_int(absent))
    rec.permission = max(0, to_int(permission))
    rec.note = note.strip()

    db.session.commit()
    return {"ok": True}

@teacher_bp.get("/print/student/<int:student_id>")
@login_required
@require_role("TEACHER")
def print_student(student_id: int):
    classroom = _my_classroom()
    if not classroom:
        return "មិនទាន់បានកំណត់ថ្នាក់សម្រាប់គ្រូ", 400

    term_id = request.args.get("term_id", type=int)
    term = Term.query.get(term_id) if term_id else None
    if not term:
        return "ខ្វះប្រចាំខែ", 400

    student = Student.query.get(student_id)
    if not student or student.class_id != classroom.id:
        return "រកមិនឃើញសិស្ស", 404

    subjects = Subject.query.order_by(Subject.name.asc()).all()
    marks = Mark.query.filter_by(student_id=student.id, term_id=term.id).all()
    mark_map = {m.subject_id: m.score for m in marks}

    avg = student_weighted_avg(student.id, term.id)
    rank_map = rank_map_for_class(classroom.id, term.id)
    rank = rank_map.get(student.id)

    rec = StudentMonthlyRecord.query.filter_by(student_id=student.id, term_id=term.id).first()

    return render_template(
        "teacher/print_student.html",
        classroom=classroom,
        term=term,
        student=student,
        subjects=subjects,
        mark_map=mark_map,
        avg=avg,
        rank=rank,
        rec=rec,
        teacher=_my_teacher(),
    )
