from flask import render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user, current_user
from . import auth_bp
from ..models import User

@auth_bp.get("/login")
def login():
    if current_user.is_authenticated:
        if current_user.has_role("ADMIN"):
            return redirect(url_for("admin.dashboard"))
        if current_user.has_role("TEACHER"):
            return redirect(url_for("teacher.dashboard"))
        return redirect(url_for("user.dashboard"))
    return render_template("auth/login.html")

@auth_bp.post("/login")
def login_post():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "")

    user = User.query.filter_by(username=username, is_active=True).first()
    if not user or not user.check_password(password):
        flash("ឈ្មោះអ្នកប្រើ ឬ ពាក្យសម្ងាត់ មិនត្រឹមត្រូវ", "danger")
        return redirect(url_for("auth.login"))

    login_user(user)
    if user.has_role("ADMIN"):
        return redirect(url_for("admin.dashboard"))
    if user.has_role("TEACHER"):
        return redirect(url_for("teacher.dashboard"))
    return redirect(url_for("user.dashboard"))

@auth_bp.get("/logout")
def logout():
    logout_user()
    return redirect(url_for("auth.login"))
