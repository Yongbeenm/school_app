from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import relationship
from ..extensions import db

class ClassRoom(db.Model):
    __tablename__ = "classes"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(60), unique=True, nullable=False)

class Student(db.Model):
    __tablename__ = "students"
    id = db.Column(db.Integer, primary_key=True)
    student_code = db.Column(db.String(30), unique=True, nullable=False)
    full_name = db.Column(db.String(120), nullable=False)
    class_id = db.Column(db.Integer, db.ForeignKey("classes.id"), nullable=False)

    classroom = relationship("ClassRoom", backref="students")

class Subject(db.Model):
    __tablename__ = "subjects"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    weight = db.Column(db.Float, nullable=False, default=1.0)

class Term(db.Model):
    __tablename__ = "terms"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    starts_at = db.Column(db.Date, nullable=True)
    ends_at = db.Column(db.Date, nullable=True)

class Mark(db.Model):
    __tablename__ = "marks"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey("students.id"), nullable=False)
    subject_id = db.Column(db.Integer, db.ForeignKey("subjects.id"), nullable=False)
    term_id = db.Column(db.Integer, db.ForeignKey("terms.id"), nullable=False)
    score = db.Column(db.Float, nullable=False)

    student = relationship("Student")
    subject = relationship("Subject")
    term = relationship("Term")

    __table_args__ = (
        UniqueConstraint("student_id", "subject_id", "term_id", name="uq_student_subject_term"),
    )


class StudentMonthlyRecord(db.Model):
    __tablename__ = "student_monthly_records"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(db.Integer, db.ForeignKey("students.id"), nullable=False)
    term_id = db.Column(db.Integer, db.ForeignKey("terms.id"), nullable=False)
    absent = db.Column(db.Integer, nullable=False, default=0)
    permission = db.Column(db.Integer, nullable=False, default=0)
    note = db.Column(db.Text, nullable=False, default="")

    student = relationship("Student", backref="monthly_records")
    term = relationship("Term")

    __table_args__ = (
        UniqueConstraint("student_id", "term_id", name="uq_student_term_monthly_record"),
    )
