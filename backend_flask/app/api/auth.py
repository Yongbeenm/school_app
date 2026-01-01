from functools import wraps
from flask import request, current_app
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
from ..models import User

def _serializer():
    return URLSafeTimedSerializer(current_app.config["SECRET_KEY"], salt="api-token")

def make_token(user: User) -> str:
    return _serializer().dumps({"uid": user.id})

def verify_token(token: str, max_age_seconds: int = 60 * 60 * 24 * 7):
    try:
        data = _serializer().loads(token, max_age=max_age_seconds)
        uid = int(data.get("uid"))
        return User.query.get(uid)
    except (BadSignature, SignatureExpired, Exception):
        return None

def require_token(*roles):
    roles = set(roles or [])
    def deco(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            auth = request.headers.get("Authorization", "")
            token = ""
            if auth.lower().startswith("bearer "):
                token = auth.split(" ", 1)[1].strip()
            if not token:
                return {"ok": False, "error": "unauthorized"}, 401
            user = verify_token(token)
            if not user:
                return {"ok": False, "error": "unauthorized"}, 401
            if roles:
                if not any(user.has_role(r) for r in roles):
                    return {"ok": False, "error": "forbidden"}, 403
            request.api_user = user  # type: ignore
            return fn(*args, **kwargs)
        return wrapper
    return deco
