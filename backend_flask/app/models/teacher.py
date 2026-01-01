from sqlalchemy import UniqueConstraint
from sqlalchemy.orm import relationship
from ..extensions import db

class Teacher(db.Model):
    __tablename__ = "teachers"
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(120), nullable=False)

    # 1 room (class) for 1 teacher
    class_id = db.Column(db.Integer, db.ForeignKey("classes.id"), nullable=True, unique=True)
    classroom = relationship("ClassRoom")

    __table_args__ = (
        UniqueConstraint("class_id", name="uq_teacher_class"),
    )
