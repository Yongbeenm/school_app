from .user import User, Role, user_roles
from .academic import ClassRoom, Student, Subject, Term, Mark, StudentMonthlyRecord
from .teacher import Teacher

__all__ = [
    "User", "Role", "user_roles",
    "ClassRoom", "Student", "Subject", "Term", "Mark", "StudentMonthlyRecord",
    "Teacher",
]
