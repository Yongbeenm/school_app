from flask import render_template, request, redirect, url_for, flash
from flask_login import login_required
from . import admin_bp
from ..extensions import db
from ..models import ClassRoom, Student, User, Role, Teacher, user_roles, Term
from ..services.authz import require_role
from ..services.ranking_service import class_ranking_rows
from ..services.code_service import next_student_code

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

@admin_bp.get("/dashboard")
@login_required
@require_role("ADMIN")
def dashboard():
    return render_template(
        "admin/dashboard.html",
        students=Student.query.count(),
        teachers=Teacher.query.count(),
        classes=ClassRoom.query.count(),
        months=Term.query.count(),
    )

# ---------- Classes (Rooms) ----------
@admin_bp.get("/classes")
@login_required
@require_role("ADMIN")
def classes_list():
    classes = ClassRoom.query.order_by(ClassRoom.name).all()
    teachers_by_class = {t.class_id: t for t in Teacher.query.filter(Teacher.class_id.isnot(None)).all()}
    return render_template("admin/classes.html", classes=classes, teachers_by_class=teachers_by_class)

@admin_bp.post("/classes")
@login_required
@require_role("ADMIN")
def classes_create():
    name = request.form.get("name", "").strip()
    if not name:
        flash("ត្រូវបញ្ចូលឈ្មោះថ្នាក់", "danger")
        return redirect(url_for("admin.classes_list"))
    if ClassRoom.query.filter_by(name=name).first():
        flash("ថ្នាក់នេះមានរួចហើយ", "warning")
        return redirect(url_for("admin.classes_list"))
    db.session.add(ClassRoom(name=name))
    db.session.commit()
    flash("បានបង្កើតថ្នាក់រួចរាល់", "success")
    return redirect(url_for("admin.classes_list"))

@admin_bp.post("/classes/<int:class_id>/delete")
@login_required
@require_role("ADMIN")
def classes_delete(class_id: int):
    c = ClassRoom.query.get(class_id)
    if not c:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("admin.classes_list"))
    if Student.query.filter_by(class_id=class_id).count() > 0:
        flash("មិនអាចលុបបានទេ ព្រោះថ្នាក់មានសិស្ស", "warning")
        return redirect(url_for("admin.classes_list"))
    # unassign teacher if any
    t = Teacher.query.filter_by(class_id=class_id).first()
    if t:
        t.class_id = None
    db.session.delete(c)
    db.session.commit()
    flash("បានលុបថ្នាក់រួចរាល់", "success")
    return redirect(url_for("admin.classes_list"))

# ---------- Students ----------
@admin_bp.get("/students")
@login_required
@require_role("ADMIN")
def students_list():
    return render_template(
        "admin/students.html",
        classes=ClassRoom.query.order_by(ClassRoom.name).all(),
        students=Student.query.order_by(Student.full_name).all(),
    )

@admin_bp.post("/students")
@login_required
@require_role("ADMIN")
def students_create():
    full_name = request.form.get("full_name", "").strip()
    class_id = request.form.get("class_id", "").strip()
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "").strip()

    if not (full_name and class_id):
        flash("ត្រូវបញ្ចូលឈ្មោះ និង ជ្រើសថ្នាក់", "danger")
        return redirect(url_for("admin.students_list"))

    classroom = ClassRoom.query.get(int(class_id))
    if not classroom:
        flash("ថ្នាក់មិនត្រឹមត្រូវ", "danger")
        return redirect(url_for("admin.students_list"))

    student_code = next_student_code()

    student = Student(student_code=student_code, full_name=full_name, class_id=classroom.id)
    db.session.add(student)
    db.session.flush()

    # login is optional: if password provided, create user
    if password:
        if not username:
            username = student_code.lower()
        if User.query.filter_by(username=username).first():
            flash("ឈ្មោះអ្នកប្រើមានរួចហើយ", "warning")
            db.session.rollback()
            return redirect(url_for("admin.students_list"))

        user = User(username=username, student_id=student.id, teacher_id=None)
        user.set_password(password)

        student_role = _get_or_create_role("STUDENT")
        user.roles.append(student_role)
        db.session.add(user)

    db.session.commit()
    flash("បានបង្កើតសិស្សរួចរាល់", "success")
    return redirect(url_for("admin.students_list"))

    if Student.query.filter_by(student_code=student_code).first():
        flash("លេខសម្គាល់សិស្សមានរួចហើយ", "warning")
        return redirect(url_for("admin.students_list"))

    if User.query.filter_by(username=username).first():
        flash("ឈ្មោះអ្នកប្រើមានរួចហើយ", "warning")
        return redirect(url_for("admin.students_list"))

    classroom = ClassRoom.query.get(int(class_id))
    if not classroom:
        flash("ថ្នាក់មិនត្រឹមត្រូវ", "danger")
        return redirect(url_for("admin.students_list"))

    student = Student(student_code=student_code, full_name=full_name, class_id=classroom.id)
    db.session.add(student)
    db.session.flush()

    user = User(username=username, student_id=student.id, teacher_id=None)
    user.set_password(password)

    student_role = _get_or_create_role("STUDENT")
    user.roles.append(student_role)
    db.session.add(user)

    db.session.commit()
    flash("បានបង្កើតសិស្ស និងគណនីចូលប្រើប្រាស់", "success")
    return redirect(url_for("admin.students_list"))

@admin_bp.post("/students/<int:student_id>/delete")
@login_required
@require_role("ADMIN")
def students_delete(student_id: int):
    from ..models import Mark
    s = Student.query.get(student_id)
    if not s:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("admin.students_list"))
    Mark.query.filter_by(student_id=student_id).delete()
    u = User.query.filter_by(student_id=student_id).first()
    if u:
        _delete_user(u)
    db.session.delete(s)
    db.session.commit()
    flash("បានលុបសិស្សរួចរាល់", "success")
    return redirect(url_for("admin.students_list"))

# ---------- Teachers + 1 class per teacher ----------
@admin_bp.get("/teachers")
@login_required
@require_role("ADMIN")
def teachers_list():
    teachers = Teacher.query.order_by(Teacher.full_name).all()
    users = {u.teacher_id: u for u in User.query.filter(User.teacher_id.isnot(None)).all()}
    classes = ClassRoom.query.order_by(ClassRoom.name).all()
    return render_template("admin/teachers.html", teachers=teachers, users=users, classes=classes)

@admin_bp.post("/teachers")
@login_required
@require_role("ADMIN")
def teachers_create():
    full_name = request.form.get("full_name", "").strip()
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "").strip()
    class_id = request.form.get("class_id", type=int)

    if not (full_name and username and password):
        flash("ត្រូវបញ្ចូលព័ត៌មានគ្រប់ចំណុច", "danger")
        return redirect(url_for("admin.teachers_list"))
    if User.query.filter_by(username=username).first():
        flash("ឈ្មោះអ្នកប្រើមានរួចហើយ", "warning")
        return redirect(url_for("admin.teachers_list"))

    if class_id and Teacher.query.filter_by(class_id=class_id).first():
        flash("ថ្នាក់នេះមានគ្រូរួចហើយ", "warning")
        return redirect(url_for("admin.teachers_list"))

    teacher = Teacher(full_name=full_name, class_id=class_id)
    db.session.add(teacher)
    db.session.flush()

    user = User(username=username, student_id=None, teacher_id=teacher.id)
    user.set_password(password)
    teacher_role = _get_or_create_role("TEACHER")
    user.roles.append(teacher_role)
    db.session.add(user)
    db.session.commit()

    flash("បានបង្កើតគ្រូ និងគណនីចូលប្រើប្រាស់", "success")
    return redirect(url_for("admin.teachers_list"))

@admin_bp.post("/teachers/<int:teacher_id>/assign")
@login_required
@require_role("ADMIN")
def teachers_assign_class(teacher_id: int):
    class_id = request.form.get("class_id", type=int)
    teacher = Teacher.query.get(teacher_id)
    if not teacher:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("admin.teachers_list"))

    if class_id and Teacher.query.filter(Teacher.class_id == class_id, Teacher.id != teacher_id).first():
        flash("ថ្នាក់នេះមានគ្រូរួចហើយ", "warning")
        return redirect(url_for("admin.teachers_list"))

    teacher.class_id = class_id or None
    db.session.commit()
    flash("បានកែប្រែថ្នាក់គ្រូរួចរាល់", "success")
    return redirect(url_for("admin.teachers_list"))

@admin_bp.post("/teachers/<int:teacher_id>/delete")
@login_required
@require_role("ADMIN")
def teachers_delete(teacher_id: int):
    teacher = Teacher.query.get(teacher_id)
    if not teacher:
        flash("រកមិនឃើញ", "danger")
        return redirect(url_for("admin.teachers_list"))

    u = User.query.filter_by(teacher_id=teacher_id).first()
    if u:
        _delete_user(u)

    db.session.delete(teacher)
    db.session.commit()
    flash("បានលុបគ្រូរួចរាល់", "success")
    return redirect(url_for("admin.teachers_list"))

# ---------- Ranking (Admin can view rankings) ----------
@admin_bp.get("/ranking")
@login_required
@require_role("ADMIN")
def ranking():
    classes = ClassRoom.query.order_by(ClassRoom.name).all()
    months = Term.query.order_by(Term.name).all()

    class_id = request.args.get("class_id", type=int)
    term_id = request.args.get("term_id", type=int)

    rows = []
    selected_class = None
    selected_term = None

    if class_id and term_id:
        selected_class = ClassRoom.query.get(class_id)
        selected_term = Term.query.get(term_id)
        if selected_class and selected_term:
            rows = class_ranking_rows(class_id, term_id)

    return render_template(
        "admin/ranking.html",
        classes=classes,
        terms=months,
        rows=rows,
        selected_class=selected_class,
        selected_term=selected_term,
    )
