from ..extensions import db
from ..models import Role, User

def ensure_role(name: str) -> Role:
    role = Role.query.filter_by(name=name).first()
    if not role:
        role = Role(name=name)
        db.session.add(role)
        db.session.commit()
    return role

def create_admin(username: str, password: str):
    admin_role = ensure_role("ADMIN")
    ensure_role("STUDENT")
    ensure_role("TEACHER")

    existing = User.query.filter_by(username=username).first()
    if existing:
        return False

    admin = User(username=username, student_id=None, teacher_id=None)
    admin.set_password(password)
    admin.roles.append(admin_role)
    db.session.add(admin)
    db.session.commit()
    return True
