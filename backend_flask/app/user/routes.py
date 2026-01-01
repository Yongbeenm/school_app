from flask import render_template, request
from flask_login import login_required, current_user
from . import user_bp
from ..extensions import db
from ..models import Term, Student, ClassRoom, Mark, Subject
from ..services.authz import require_role
from ..services.ranking_service import student_weighted_avg, rank_map_for_class

@user_bp.get("/dashboard")
@login_required
@require_role("STUDENT")
def dashboard():
    if not current_user.student_id:
        return "គណនីសិស្សមិនទាន់ភ្ជាប់ជាមួយទិន្នន័យសិស្សទេ។", 400

    terms = Term.query.order_by(Term.id.asc()).all()
    term_id = request.args.get("term_id", type=int)
    if not term_id and terms:
        term_id = terms[-1].id

    student = Student.query.get(current_user.student_id)
    classroom = ClassRoom.query.get(student.class_id) if student else None
    term = Term.query.get(term_id) if term_id else None

    marks = []
    if term and student:
        marks = (
            db.session.query(Mark, Subject)
            .join(Subject, Subject.id == Mark.subject_id)
            .filter(Mark.student_id == student.id, Mark.term_id == term.id)
            .order_by(Subject.name.asc())
            .all()
        )

    avg_score = student_weighted_avg(student.id, term.id) if student and term else None
    rank_map = rank_map_for_class(student.class_id, term.id) if student and term else {}
    my_rank = rank_map.get(student.id)
    total_ranked = len(rank_map)

    monthly_rec = StudentMonthlyRecord.query.filter_by(student_id=student.id, term_id=selected_term.id).first() if selected_term else None

    return render_template(
        "user/dashboard.html",
        student=student,
        classroom=classroom,
        terms=terms,
        selected_term=term,
        marks=marks,
        avg_score=avg_score,
        my_rank=my_rank,
        total_ranked=total_ranked,
    )
