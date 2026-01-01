from flask import Flask, redirect, url_for
from flask_cors import CORS
from dotenv import load_dotenv

from .config import Config
from .extensions import db, login_manager, migrate
from .i18n import inject_i18n
from .models import User

def create_app():
    load_dotenv()
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    login_manager.init_app(app)
    migrate.init_app(app, db)

    login_manager.login_view = "auth.login"

    # Enable CORS for Flutter / API usage
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    @login_manager.user_loader
    def load_user(user_id: str):
        return User.query.get(int(user_id))

    # Blueprints
    from .auth import auth_bp
    from .admin import admin_bp
    from .teacher import teacher_bp
    from .user import user_bp
    from .pages import pages_bp
    from .api import api_bp

    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(admin_bp, url_prefix="/admin")
    app.register_blueprint(teacher_bp, url_prefix="/teacher")
    app.register_blueprint(user_bp, url_prefix="/user")
    app.register_blueprint(pages_bp)
    app.register_blueprint(api_bp)

    @app.context_processor
    def ctx_i18n():
        return inject_i18n()

    @app.get("/")
    def index():
        return redirect(url_for("auth.login"))

    return app
