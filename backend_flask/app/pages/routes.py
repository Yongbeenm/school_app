from flask import render_template
from flask_login import current_user
from . import pages_bp

@pages_bp.get("/help")
def help():
    role = "guest"
    if getattr(current_user, "is_authenticated", False):
        if current_user.has_role("ADMIN"):
            role = "admin"
        elif current_user.has_role("TEACHER"):
            role = "teacher"
        elif current_user.has_role("STUDENT"):
            role = "student"
    return render_template("pages/help.html", default_role=role)
