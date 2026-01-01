from sqlalchemy import func
from ..extensions import db
from ..models import Student, Mark, Subject

def class_ranking_rows(class_id: int, term_id: int):
    avg_subq = (
        db.session.query(
            Student.id.label("student_id"),
            Student.student_code.label("student_code"),
            Student.full_name.label("full_name"),
            (func.sum(Mark.score * Subject.weight) / func.nullif(func.sum(Subject.weight), 0)).label("avg_score"),
        )
        .join(Mark, Mark.student_id == Student.id)
        .join(Subject, Subject.id == Mark.subject_id)
        .filter(Student.class_id == class_id, Mark.term_id == term_id)
        .group_by(Student.id, Student.student_code, Student.full_name)
        .subquery()
    )

    ranked = (
        db.session.query(
            avg_subq.c.student_id,
            avg_subq.c.student_code,
            avg_subq.c.full_name,
            avg_subq.c.avg_score,
            func.rank().over(order_by=avg_subq.c.avg_score.desc()).label("rank"),
        )
        .order_by("rank", avg_subq.c.full_name.asc())
        .all()
    )

    return [
        {
            "student_id": r.student_id,
            "student_code": r.student_code,
            "full_name": r.full_name,
            "avg_score": float(r.avg_score) if r.avg_score is not None else None,
            "rank": int(r.rank) if r.rank is not None else None,
        }
        for r in ranked
    ]

def student_weighted_avg(student_id: int, term_id: int):
    row = (
        db.session.query(
            (func.sum(Mark.score * Subject.weight) / func.nullif(func.sum(Subject.weight), 0)).label("avg_score")
        )
        .join(Subject, Subject.id == Mark.subject_id)
        .filter(Mark.student_id == student_id, Mark.term_id == term_id)
        .first()
    )
    return float(row.avg_score) if row and row.avg_score is not None else None

def rank_map_for_class(class_id: int, term_id: int):
    rows = class_ranking_rows(class_id, term_id)
    return {int(r["student_id"]): int(r["rank"]) for r in rows if r["student_id"] and r["rank"]}
